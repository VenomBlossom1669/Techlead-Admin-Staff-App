const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json'); // your downloaded JSON

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function sendMulticastNotification(fcmTokens, taskData) {
  const message = {
    notification: {
      title: 'New Task Assigned',
      body: `You have been assigned a new task: ${taskData.taskDescription}`,
    },
    data: {
      taskId: taskData.taskId,
      taskDescription: taskData.taskDescription,
      deadlineDate: taskData.deadlineDate,
    },
    tokens: fcmTokens,
  };

  const response = await admin.messaging().sendMulticast(message);
  console.log(`${response.successCount} messages were sent successfully`);
}
