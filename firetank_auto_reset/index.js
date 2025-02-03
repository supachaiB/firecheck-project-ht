const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.scheduledResetStatusEndOfMonth = functions.pubsub
    .schedule("59 23 28-31 * *") // ทุกวันสุดท้ายของเดือนเวลา 23:59
    .timeZone("Asia/Bangkok")
    .onRun(async (context) => {
      const db = admin.firestore();
      const now = new Date();
      const lastDayOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

      // เช็คว่ามีการทำงานในวันสุดท้ายของเดือน
      if (now.getDate() === lastDayOfMonth.getDate()) {
        const snapshot = await db.collection("firetank_Collection").get();

        const batch = db.batch();
        snapshot.docs.forEach((doc) => {
          batch.update(doc.ref, {status: "ยังไม่ตรวจสอบ"});
        });

        await batch.commit();
        console.log("Reset all tank statuses at the end of the month");
      }
      return null;
    });
