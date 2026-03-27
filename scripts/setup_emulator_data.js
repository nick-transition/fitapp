const admin = require('firebase-admin');

// Point to emulators
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';

admin.initializeApp({
  projectId: 'fitapp-ns',
});

async function setup() {
  const db = admin.firestore();
  const auth = admin.auth();

  console.log('--- Setting up Mock User ---');
  let user;
  try {
    user = await auth.createUser({
      uid: 'mock-user-123',
      email: 'testuser@gmail.com',
      displayName: 'Test User',
      photoURL: 'https://via.placeholder.com/150',
    });
    console.log(`User created: ${user.uid}`);
  } catch (e) {
    if (e.code === 'auth/uid-already-exists') {
      console.log('User already exists, proceeding.');
      user = { uid: 'mock-user-123' };
    } else {
      console.error('Error creating user:', e);
      return;
    }
  }

  console.log('--- Setting up OAuth Client ---');
  const clientId = 'claude-ai-connector';
  const clientSecret = 'sk_test_' + require('crypto').randomBytes(16).toString('hex');
  
  await db.collection('oauthClients').doc(clientId).set({
    name: 'Claude AI Connector',
    secret: clientSecret,
    redirectUris: ['https://claude.ai/oauth/callback'],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  
  console.log('OAuth Client Created:');
  console.log(`Client ID: ${clientId}`);
  console.log(`Client Secret: ${clientSecret}`);

  console.log('--- Done ---');
  process.exit(0);
}

setup();
