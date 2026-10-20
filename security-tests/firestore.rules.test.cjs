const { readFileSync } = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, getDocs, collection, query, where, setDoc, updateDoc, serverTimestamp, or, and, runTransaction } = require('firebase/firestore');

const projectId = 'demo-life-os';
let env;
const members = ['abdullah-test', 'jannat-test', 'other-test', 'active-outsider-test'];

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all(members.map((uid) => setDoc(doc(db, 'lifeOsMembers', uid), {
      active: uid !== 'other-test',
      peerUid: uid === 'abdullah-test' ? 'jannat-test' : uid === 'jannat-test' ? 'abdullah-test' : null,
    })));
  });
});

after(async () => env?.cleanup());

function task(ownerUid, assigneeUid, extras = {}) {
  return {
    ownerUid,
    assigneeUid,
    title: 'Review roadmap',
    date: '2026-10-15',
    priority: 1,
    durationMinutes: 45,
    deadline: '2026-10-20',
    notes: 'Prepare a short summary.',
    status: 'notDone',
    revoked: false,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    ...extras,
  };
}

test('owner assigns task and assignee can update only its status', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  const assignee = env.authenticatedContext('jannat-test').firestore();
  const ref = doc(owner, 'sharedTasks', 'task-1');
  await assertSucceeds(setDoc(ref, task('abdullah-test', 'jannat-test')));
  const inbox = query(
    collection(assignee, 'sharedTasks'),
    where('assigneeUid', '==', 'jannat-test'),
    where('revoked', '==', false),
  );
  const result = await assertSucceeds(getDocs(inbox));
  if (result.size !== 1 || result.docs[0].id !== 'task-1') {
    throw new Error('Assignee query did not return the expected task.');
  }
  const appQuery = query(
    collection(assignee, 'sharedTasks'),
    or(
      where('ownerUid', '==', 'jannat-test'),
      and(
        where('assigneeUid', '==', 'jannat-test'),
        where('revoked', '==', false),
      ),
    ),
  );
  await assertSucceeds(getDocs(appQuery));
  await assertSucceeds(updateDoc(doc(assignee, 'sharedTasks', 'task-1'), {
    status: 'partial', updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(assignee, 'sharedTasks', 'task-1'), {
    title: 'Changed by assignee', updatedAt: serverTimestamp(),
  }));
  const saved = await assertSucceeds(getDoc(doc(owner, 'sharedTasks', 'task-1')));
  if (saved.data().status !== 'partial') throw new Error('Status update was not synchronized.');
});

test('unapproved account, unrelated account, and unauthenticated access are denied', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  await assertSucceeds(setDoc(doc(owner, 'sharedTasks', 'task-2'), task('abdullah-test', 'jannat-test')));
  const unrelated = env.authenticatedContext('other-test').firestore();
  await assertFails(getDoc(doc(unrelated, 'sharedTasks', 'task-2')));
  await assertFails(setDoc(doc(unrelated, 'sharedTasks', 'malicious'), task('other-test', 'abdullah-test')));
  const anonymous = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anonymous, 'sharedTasks', 'task-2')));
  const otherMember = env.authenticatedContext('carol-test').firestore();
  await assertFails(getDoc(doc(otherMember, 'sharedTasks', 'task-2')));
  await assertFails(updateDoc(doc(otherMember, 'sharedTasks', 'task-2'), {
    status: 'done', updatedAt: serverTimestamp(),
  }));
});

test('active member can read an absent task for keyed creation without reading another task', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  const missing = await assertSucceeds(
    getDoc(doc(owner, 'sharedTasks', 'not-created-yet')),
  );
  if (missing.exists()) throw new Error('The test task unexpectedly exists.');

  await assertSucceeds(
    setDoc(doc(owner, 'sharedTasks', 'existing-private-party-check'),
      task('abdullah-test', 'jannat-test')),
  );
  const unrelated = env.authenticatedContext('active-outsider-test').firestore();
  const stillMissing = await assertSucceeds(
    getDoc(doc(unrelated, 'sharedTasks', 'another-not-created-yet')),
  );
  if (stillMissing.exists()) throw new Error('The outsider path unexpectedly exists.');
  await assertFails(
    getDoc(doc(unrelated, 'sharedTasks', 'existing-private-party-check')),
  );
});

test('private records and membership writes remain denied', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  const recipient = env.authenticatedContext('jannat-test').firestore();
  const membership = await assertSucceeds(getDoc(doc(owner, 'lifeOsMembers', 'abdullah-test')));
  if (membership.data().peerUid !== 'jannat-test') throw new Error('Trusted peer was not provisioned.');
  await assertFails(getDoc(doc(owner, 'lifeOsMembers', 'jannat-test')));
  await assertFails(getDocs(query(collection(owner, 'lifeOsMembers'), where('active', '==', true))));
  await assertFails(setDoc(doc(owner, 'users', 'abdullah-test', 'records', 'private-1'), { visibility: 'private' }));
  await assertFails(getDoc(doc(recipient, 'users', 'abdullah-test', 'records', 'private-1')));
  await assertFails(setDoc(doc(owner, 'lifeOsMembers', 'attacker'), { active: true }));
  const unapproved = env.authenticatedContext('other-test').firestore();
  await assertFails(getDocs(query(collection(unapproved, 'lifeOsMembers'), where('active', '==', true))));
  await assertFails(getDoc(doc(unapproved, 'lifeOsMembers', 'other-test')));
});

test('rejects forged task ownership and unregistered recipients', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  await assertFails(setDoc(doc(owner, 'sharedTasks', 'forged-owner'), task('jannat-test', 'abdullah-test')));
  await assertFails(setDoc(doc(owner, 'sharedTasks', 'unknown-assignee'), task('abdullah-test', 'other-test')));
  await assertFails(setDoc(doc(owner, 'sharedTasks', 'unpaired-assignee'), task('abdullah-test', 'abdullah-test')));
  await assertFails(setDoc(doc(owner, 'sharedTasks', 'bad-status'), task('abdullah-test', 'jannat-test', { status: 'complete' })));
  await assertFails(setDoc(doc(owner, 'sharedTasks', 'extra-data'), task('abdullah-test', 'jannat-test', { privateEvidence: 'must-not-upload' })));
});

test('owner revocation immediately removes the assignee read and write access', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  const assignee = env.authenticatedContext('jannat-test').firestore();
  const ref = doc(owner, 'sharedTasks', 'revoked-task');
  await assertSucceeds(setDoc(ref, task('abdullah-test', 'jannat-test')));
  await assertSucceeds(updateDoc(ref, { revoked: true, updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(assignee, 'sharedTasks', 'revoked-task')));
  await assertFails(updateDoc(doc(assignee, 'sharedTasks', 'revoked-task'), {
    status: 'done', updatedAt: serverTimestamp(),
  }));
  // The owner retains access to the tombstone for audit and re-sharing decisions.
  await assertSucceeds(getDoc(ref));
  await assertFails(updateDoc(ref, { revoked: false, updatedAt: serverTimestamp() }));
});

class IdempotencyConflict extends Error {}

function sameAssignment(existing, requested) {
  return [
    'ownerUid', 'assigneeUid', 'title', 'date', 'priority',
    'durationMinutes', 'deadline', 'notes',
  ].every((key) => existing[key] === requested[key]);
}

async function createTaskIdempotently(db, ref, requested) {
  return runTransaction(db, async (transaction) => {
    const existing = await transaction.get(ref);
    if (existing.exists()) {
      if (!sameAssignment(existing.data(), requested)) {
        throw new IdempotencyConflict('Key already belongs to a different assignment.');
      }
      return 'existing';
    }
    transaction.set(ref, {
      ...requested,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    return 'created';
  });
}

test('exact deterministic retry is a no-op and preserves status and timestamps', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  const ref = doc(owner, 'sharedTasks', 'stable-idempotency-key');
  const requested = task('abdullah-test', 'jannat-test');
  await assertSucceeds(createTaskIdempotently(owner, ref, requested));
  const assignee = env.authenticatedContext('jannat-test').firestore();
  await assertSucceeds(updateDoc(doc(assignee, 'sharedTasks', ref.id), {
    status: 'partial', updatedAt: serverTimestamp(),
  }));
  const beforeRetry = await assertSucceeds(getDoc(ref));
  const beforeCreatedAt = beforeRetry.data().createdAt;
  const beforeUpdatedAt = beforeRetry.data().updatedAt;
  await assertSucceeds(createTaskIdempotently(owner, ref, requested));
  const afterRetry = await assertSucceeds(getDoc(ref));
  if (afterRetry.data().createdAt.toMillis() !== beforeCreatedAt.toMillis()) {
    throw new Error('An exact retry changed the original creation timestamp.');
  }
  if (afterRetry.data().updatedAt.toMillis() !== beforeUpdatedAt.toMillis()) {
    throw new Error('An exact retry performed a second write.');
  }
  if (afterRetry.data().status !== 'partial') {
    throw new Error('An exact retry reset the assignee status.');
  }
  const tasks = await assertSucceeds(getDocs(query(
    collection(owner, 'sharedTasks'),
    where('ownerUid', '==', 'abdullah-test'),
  )));
  if (tasks.docs.filter((snapshot) => snapshot.id === ref.id).length !== 1) {
    throw new Error('A retry created a duplicate shared task.');
  }
});

test('same idempotency key with changed owner, assignee, or payload conflicts unchanged', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  const ref = doc(owner, 'sharedTasks', 'conflicting-idempotency-key');
  const requested = task('abdullah-test', 'jannat-test');
  await assertSucceeds(createTaskIdempotently(owner, ref, requested));
  const original = (await assertSucceeds(getDoc(ref))).data();
  const variants = [
    { ownerUid: 'other-test' },
    { assigneeUid: 'other-test' },
    { title: 'Different title' },
    { date: '2026-10-16' },
    { priority: 2 },
    { durationMinutes: 60 },
    { deadline: null },
    { notes: 'Different notes' },
  ];
  for (const change of variants) {
    await assert.rejects(
      createTaskIdempotently(owner, ref, { ...requested, ...change }),
      IdempotencyConflict,
    );
    const after = (await assertSucceeds(getDoc(ref))).data();
    for (const field of [
      'ownerUid', 'assigneeUid', 'title', 'date', 'priority',
      'durationMinutes', 'deadline', 'notes', 'status', 'revoked',
    ]) {
      if (after[field] !== original[field]) {
        throw new Error(`Conflict changed stored field ${field}.`);
      }
    }
    if (after.createdAt.toMillis() !== original.createdAt.toMillis() ||
        after.updatedAt.toMillis() !== original.updatedAt.toMillis()) {
      throw new Error('Conflict changed stored timestamps.');
    }
  }
});

test('owner cannot silently rewrite an assignment; revocation is a tombstone', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  const ref = doc(owner, 'sharedTasks', 'immutable-assignment');
  await assertSucceeds(setDoc(ref, task('abdullah-test', 'jannat-test')));
  const forbiddenChanges = [
    { ownerUid: 'other-test' },
    { assigneeUid: 'other-test' },
    { title: 'Changed task' },
    { date: '2026-10-16' },
    { priority: 2 },
    { durationMinutes: 60 },
    { deadline: null },
    { notes: 'Changed notes' },
  ];
  for (const change of forbiddenChanges) {
    await assertFails(updateDoc(ref, { ...change, updatedAt: serverTimestamp() }));
  }
  await assertSucceeds(updateDoc(ref, { revoked: true, updatedAt: serverTimestamp() }));
});

test('rejects invalid fields, malformed dates, timestamp forgery, and owner reassignment', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  await assertFails(setDoc(doc(owner, 'sharedTasks', 'bad-date'), task('abdullah-test', 'jannat-test', { date: '15-10-2026' })));
  await assertFails(setDoc(doc(owner, 'sharedTasks', 'bad-duration'), task('abdullah-test', 'jannat-test', { durationMinutes: 0 })));
  await assertFails(setDoc(doc(owner, 'sharedTasks', 'bad-notes'), task('abdullah-test', 'jannat-test', { notes: 'x'.repeat(4001) })));
  await assertFails(setDoc(doc(owner, 'sharedTasks', 'forged-time'), task('abdullah-test', 'jannat-test', { createdAt: new Date('2020-01-01T00:00:00Z') })));
  const ref = doc(owner, 'sharedTasks', 'immutable-owner');
  await assertSucceeds(setDoc(ref, task('abdullah-test', 'jannat-test')));
  await assertFails(updateDoc(ref, { ownerUid: 'jannat-test', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { revoked: true, assigneeUid: 'other-test', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { revoked: true, updatedAt: serverTimestamp(), injected: true }));
  await assertFails(updateDoc(ref, { status: 'done', updatedAt: new Date() }));
});

test('inactive membership revokes access to previously shared tasks', async () => {
  const owner = env.authenticatedContext('abdullah-test').firestore();
  const assignee = env.authenticatedContext('jannat-test').firestore();
  await assertSucceeds(setDoc(doc(owner, 'sharedTasks', 'membership-revoked'), task('abdullah-test', 'jannat-test')));
  await env.withSecurityRulesDisabled(async (context) => {
    await updateDoc(doc(context.firestore(), 'lifeOsMembers', 'jannat-test'), { active: false });
  });
  await assertFails(getDoc(doc(assignee, 'sharedTasks', 'membership-revoked')));
  await assertFails(updateDoc(doc(assignee, 'sharedTasks', 'membership-revoked'), {
    status: 'done', updatedAt: serverTimestamp(),
  }));
});
