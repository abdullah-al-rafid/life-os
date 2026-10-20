const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc } = require('firebase/firestore');

const projectId = 'demo-life-os';
const [ownerUid, assigneeUid] = process.argv.slice(2);

if (!ownerUid || !assigneeUid || ownerUid === assigneeUid) {
  console.error(
    'Usage: node security-tests/seed-emulator-members.cjs <owner-uid> <assignee-uid>',
  );
  process.exitCode = 2;
} else {
  seed().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

async function seed() {
  const environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: `rules_version = '2';
        service cloud.firestore {
          match /databases/{database}/documents {
            match /{document=**} { allow read, write: if false; }
          }
        }`,
    },
  });

  try {
    await environment.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const ownerRef = doc(db, 'lifeOsMembers', ownerUid);
      const assigneeRef = doc(db, 'lifeOsMembers', assigneeUid);
      const existing = await Promise.all([
        getDoc(ownerRef),
        getDoc(assigneeRef),
      ]);
      if (existing.some((snapshot) => snapshot.exists())) {
        throw new Error(
          'A membership document already exists; refusing to overwrite emulator data.',
        );
      }
      await Promise.all([
        setDoc(ownerRef, { active: true, peerUid: assigneeUid }),
        setDoc(assigneeRef, { active: true, peerUid: ownerUid }),
      ]);
    });
    console.log(`Seeded reciprocal demo memberships for ${ownerUid} and ${assigneeUid}.`);
  } finally {
    await environment.cleanup();
  }
}
