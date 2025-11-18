import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

// 거리 계산 함수 (Haversine 공식)
function getDistance(lat1: number, lon1: number, lat2: number, lon2: number) {
  const R = 6371e3; // meters
  const toRad = (n: number) => n * Math.PI / 180;

  const φ1 = toRad(lat1);
  const φ2 = toRad(lat2);
  const Δφ = toRad(lat2 - lat1);
  const Δλ = toRad(lon2 - lon1);

  const a = Math.sin(Δφ / 2) ** 2 +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // meters
}

// ⭐ 의뢰글 생성될 때 실행되는 함수
export const notifyNearbyUsers = onDocumentCreated(
  "requests/{requestId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const reqLat = data.position.latitude;
    const reqLng = data.position.longitude;

    const usersSnap = await admin.firestore().collection("users").get();
    const tokens: string[] = [];

    usersSnap.forEach((doc) => {
      const user = doc.data();

      if (!user.position || !user.fcmToken) return;

      const distance = getDistance(
        reqLat,
        reqLng,
        user.position.latitude,
        user.position.longitude
      );

      if (distance <= 2500) {
        tokens.push(user.fcmToken);
      }
    });

    if (tokens.length === 0) return;

    // 알림 보내기
    await admin.messaging().sendMulticast({
      tokens,
      notification: {
        title: "📸 새로운 사진 의뢰가 도착했습니다!",
        body: data.title,
      }
    });

    console.log("알림 보내기 완료:", tokens.length, "명");
    return;
  }
);
