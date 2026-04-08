const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

async function assertAdmin(callerUid) {
  const callerDoc = await db.collection("users").doc(callerUid).get();
  const role = (callerDoc.data() || {}).role;
  if (role !== "admin") {
    throw new HttpsError("permission-denied", "Chỉ admin mới có quyền xóa tài khoản.");
  }
}

async function deleteQueryByField(collectionName, fieldName, fieldValue) {
  while (true) {
    const snap = await db
      .collection(collectionName)
      .where(fieldName, "==", fieldValue)
      .limit(200)
      .get();

    if (snap.empty) {
      return;
    }

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
}

async function deleteSubcollection(collectionRef) {
  while (true) {
    const snap = await collectionRef.limit(200).get();
    if (snap.empty) {
      return;
    }

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
}

exports.adminDeleteUserCascade = functions
  .region("asia-southeast1")
  .runWith({
    timeoutSeconds: 120,
    memory: "256MB",
  })
  .https.onCall(async (data, context) => {
    const callerUid = context.auth && context.auth.uid;
    if (!callerUid) {
      throw new functions.https.HttpsError("unauthenticated", "Bạn cần đăng nhập để thực hiện thao tác này.");
    }

    await assertAdmin(callerUid);

    const rawUserId = data && data.userId;
    const userId = (rawUserId || "").toString().trim();

    if (!userId) {
      throw new functions.https.HttpsError("invalid-argument", "Thiếu userId cần xóa.");
    }

    if (userId === callerUid) {
      throw new functions.https.HttpsError("failed-precondition", "Không thể tự xóa tài khoản admin đang đăng nhập.");
    }

    functions.logger.info("adminDeleteUserCascade start", {callerUid, userId});

    await deleteQueryByField("foods", "sellerId", userId);
    await deleteQueryByField("orders", "userId", userId);
    await deleteQueryByField("orders", "sellerId", userId);
    await deleteQueryByField("seller_interview_attempts", "sellerId", userId);
    await deleteQueryByField("seller_rewards", "sellerId", userId);

    await deleteSubcollection(db.collection("users").doc(userId).collection("addresses"));
    await deleteSubcollection(db.collection("favorites").doc(userId).collection("items"));

    await db.collection("favorites").doc(userId).delete().catch(() => null);
    await db.collection("users").doc(userId).delete().catch(() => null);

    try {
      await auth.deleteUser(userId);
    } catch (error) {
      if (!error || error.code !== "auth/user-not-found") {
        throw error;
      }
    }

    functions.logger.info("adminDeleteUserCascade done", {callerUid, userId});

    return {ok: true, userId};
  });
