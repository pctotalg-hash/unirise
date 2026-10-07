const API_BASE = 'http://localhost:5000/api';

async function runTests() {
  console.log('==================================================');
  console.log('🚀 RUNNING UNIRISE CRITICAL BUGS FUNCTIONAL VERIFICATION');
  console.log('==================================================\n');

  try {
    // 1. Authenticate test users
    console.log('1. Authenticating Test Users...');
    const userARes = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'aarav@unirise.demo', password: 'Student@123' })
    });
    const userAData = await userARes.json();

    const userBRes = await fetch(`${API_BASE}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'ananya@unirise.demo', password: 'Student@123' })
    });
    const userBData = await userBRes.json();

    const tokenA = userAData.token;
    const userA = userAData.user;
    const tokenB = userBData.token;
    const userB = userBData.user;

    console.log(`   User A: ${userA.name} (${userA._id})`);
    console.log(`   User B: ${userB.name} (${userB._id})`);
    console.log('   ✅ Authentication Successful.\n');

    const headersA = { 'Content-Type': 'application/json', Authorization: `Bearer ${tokenA}` };
    const headersB = { 'Content-Type': 'application/json', Authorization: `Bearer ${tokenB}` };

    // ==================================================
    // BUG 1: Create Post Verification
    // ==================================================
    console.log('--------------------------------------------------');
    console.log('TEST 1: Bug 1 — Create Post Functional Test');
    console.log('--------------------------------------------------');
    const postRes = await fetch(`${API_BASE}/posts`, {
      method: 'POST',
      headers: headersA,
      body: JSON.stringify({
        content: 'Testing Create Post functional fix in UNIRISE campus feed!',
        title: 'Automated Post Creation Test',
        category: 'Student Posts',
        media: ['https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800'],
        hashtags: ['#testing', '#unirise']
      })
    });
    const postData = await postRes.json();
    console.log('   Posted ID:', postData._id);
    console.log('   Posted Content:', postData.content);

    // Verify post is present in feed
    const feedRes = await fetch(`${API_BASE}/posts`, { headers: headersA });
    const feedData = await feedRes.json();
    const foundPost = feedData.find(p => p._id === postData._id);
    if (!foundPost) throw new Error('Created post not found in campus feed!');
    console.log('   ✅ Bug 1 Fix Verified: Create Post successfully saved to MongoDB Atlas & returned in Feed.\n');

    // ==================================================
    // BUG 4 & 5: Connection State Machine & Message Authorization
    // ==================================================
    console.log('--------------------------------------------------');
    console.log('TEST 2: Bug 4 & Bug 5 — Connection State Machine & Messaging Security');
    console.log('--------------------------------------------------');

    // Ensure clean initial state (disconnect if connected)
    const profB_initial = await (await fetch(`${API_BASE}/users/${userB._id}`, { headers: headersA })).json();
    if (profB_initial.connectionStatus === 'ACCEPTED') {
      await fetch(`${API_BASE}/users/${userB._id}/connect`, { method: 'POST', headers: headersA });
    }

    // Step 2a: Unconnected message attempt -> Expect 403 Forbidden
    console.log('   Step 2a: Attempting 1-on-1 message when unconnected...');
    const unconnMsgRes = await fetch(`${API_BASE}/messages`, {
      method: 'POST',
      headers: headersA,
      body: JSON.stringify({
        receiverId: userB._id,
        content: 'This should be blocked with 403 Forbidden!'
      })
    });

    if (unconnMsgRes.status === 403) {
      console.log('   ✅ 403 Forbidden received as expected when unconnected.');
    } else {
      const data = await unconnMsgRes.json();
      throw new Error(`FAILED: Unconnected message expected 403, got ${unconnMsgRes.status}: ${JSON.stringify(data)}`);
    }

    // Step 2b: User A sends connection request to User B
    console.log('   Step 2b: User A sends connection request to User B...');
    const connReqRes = await (await fetch(`${API_BASE}/users/${userB._id}/connect`, { method: 'POST', headers: headersA })).json();
    console.log('   Connection Request Response:', connReqRes);

    // Verify status for User A (PENDING_SENT) and User B (PENDING_RECEIVED)
    const statusA_pending = await (await fetch(`${API_BASE}/users/${userB._id}`, { headers: headersA })).json();
    const statusB_pending = await (await fetch(`${API_BASE}/users/${userA._id}`, { headers: headersB })).json();
    console.log('   Status from User A perspective:', statusA_pending.connectionStatus);
    console.log('   Status from User B perspective:', statusB_pending.connectionStatus);

    if (statusA_pending.connectionStatus !== 'PENDING_SENT') throw new Error(`Expected PENDING_SENT for User A, got ${statusA_pending.connectionStatus}`);
    if (statusB_pending.connectionStatus !== 'PENDING_RECEIVED') throw new Error(`Expected PENDING_RECEIVED for User B, got ${statusB_pending.connectionStatus}`);
    console.log('   ✅ Connection Pending status verified.');

    // Step 2c: User B accepts connection request
    console.log('   Step 2c: User B accepts connection request...');
    const connAcceptRes = await (await fetch(`${API_BASE}/users/${userA._id}/connect`, { method: 'POST', headers: headersB })).json();
    console.log('   Connection Accept Response:', connAcceptRes);

    const statusA_accepted = await (await fetch(`${API_BASE}/users/${userB._id}`, { headers: headersA })).json();
    console.log('   Status after acceptance:', statusA_accepted.connectionStatus);
    if (statusA_accepted.connectionStatus !== 'ACCEPTED') throw new Error(`Expected ACCEPTED status after acceptance, got ${statusA_accepted.connectionStatus}`);
    console.log('   ✅ Connection ACCEPTED status verified.');

    // Step 2d: User A sends 1-on-1 private message now that connected -> Expect 201 Created
    console.log('   Step 2d: User A sends 1-on-1 private message now that connected...');
    const privateMsgRes = await fetch(`${API_BASE}/messages`, {
      method: 'POST',
      headers: headersA,
      body: JSON.stringify({
        receiverId: userB._id,
        content: 'Hello Sarah, this is a private 1-on-1 connected message!'
      })
    });

    const privateMsgData = await privateMsgRes.json();
    if (!privateMsgRes.ok) throw new Error(`Failed to send private message: ${JSON.stringify(privateMsgData)}`);

    console.log('   Private Message ID:', privateMsgData._id);
    console.log('   Private Message Content:', privateMsgData.content);
    console.log('   ✅ Bug 4 & 5 Fixes Verified: Connection state transitions & Messaging Authorization work.\n');

    // ==================================================
    // BUG 2 & 3: Chat History & Group Chat Message
    // ==================================================
    console.log('--------------------------------------------------');
    console.log('TEST 3: Bug 2 & Bug 3 — Group Chat & History Retrieval');
    console.log('--------------------------------------------------');

    // Fetch campus groups
    const groupsData = await (await fetch(`${API_BASE}/groups`, { headers: headersA })).json();
    if (!groupsData || groupsData.length === 0) throw new Error('No groups found on campus');

    const testGroup = groupsData[0];
    console.log(`   Sending message to Group: ${testGroup.name} (${testGroup._id})...`);

    const groupMsgRes = await fetch(`${API_BASE}/messages`, {
      method: 'POST',
      headers: headersA,
      body: JSON.stringify({
        groupId: testGroup._id,
        content: 'Automated test group chat message for Coding Club!'
      })
    });
    const groupMsgData = await groupMsgRes.json();

    console.log('   Group Message ID:', groupMsgData._id);
    console.log('   Group Message Content:', groupMsgData.content);

    // Fetch Group Messages History
    const groupHistoryData = await (await fetch(`${API_BASE}/messages/group/${testGroup._id}`, { headers: headersA })).json();
    const foundGroupMsg = groupHistoryData.find(m => m._id === groupMsgData._id);
    if (!foundGroupMsg) throw new Error('Sent group message not found in group history!');
    console.log('   ✅ Group Chat Message saved to MongoDB Atlas & retrieved in group history.');

    // Fetch Personal Private Messages History
    const privateHistoryData = await (await fetch(`${API_BASE}/messages/private/${userB._id}`, { headers: headersA })).json();
    const foundPrivateMsg = privateHistoryData.find(m => m._id === privateMsgData._id);
    if (!foundPrivateMsg) throw new Error('Sent private message not found in private history!');
    console.log('   ✅ Personal Private Messages history retrieved successfully from MongoDB Atlas.');

    // Fetch Open Community Messages History
    const publicHistoryData = await (await fetch(`${API_BASE}/messages/public`, { headers: headersA })).json();
    console.log(`   ✅ Open Community History retrieved: ${publicHistoryData.length} messages.\n`);

    console.log('==================================================');
    console.log('🎉 ALL 5 CRITICAL FUNCTIONAL BUG TESTS PASSED 100%!');
    console.log('==================================================');

  } catch (err) {
    console.error('\n❌ TEST FAILED with error:', err.message);
    process.exit(1);
  }
}

runTests();
