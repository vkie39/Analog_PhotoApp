import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';


/* !위치 권한! 
 * 권한 확보 순서
 * - [needAlways]가 true면: WhenInUse → Always로 업셀 시도
 * - false면: WhenInUse만 확보
 * - neeaAlways는 어디까지 권한을 요청할지 지정하는 bool임
 * - false면 [앱 사용 중 허용] 까지만 검사 / true면 [항상 허용]까지 검사
 * - request에 대한 알림은 백그라운드에서 사용자의 위치를 추적하여 보내기 때문에 needAlways = true 인 상황
 */

Future<bool> ensureLocationPermission(BuildContext context, {bool needAlways = false}) async {
  // 1) 위치 서비스(GPS) 켜짐 여부도 체크(선택 사항: geolocator 등으로 확인 가능)   
 
  // 현재 상태 읽기
  var whenInUse = Permission.locationWhenInUse;    // 앱 사용중일 때 위치 권한 여부
  var always = Permission.locationAlways;          // 영구적인 위치 권한 여부 

  // iOS/Android 공통: 먼저 WhenInUse 확보
  var whenInUseStatus = await whenInUse.status;

  // permanentlyDenied인 경우: 설정 안내 (앱 내에서 다시 설정 못 함)
  if (whenInUseStatus.isPermanentlyDenied) {
    final go = await _showGoToSettingsDialog(context, reason: '위치권한이 영구 거절되어 설정에서 직접 허용해야 합니다.');
    if (go) await openAppSettings(); // 설정 화면 열기
    return false;
  }

  // 아직 승인 안 되었으면 요청
  if (!whenInUseStatus.isGranted) {
    final req = await whenInUse.request(); // 요청 다이얼로그
    if (!req.isGranted) {
      // 거절(또는 영구 거절) 시 처리
      if (req.isPermanentlyDenied) {
        final go = await _showGoToSettingsDialog(context, reason: '위치 권한이 영구 거절되었습니다. 설정에서 허용해 주세요.');
        if (go) await openAppSettings();
      } else {
        _toast(context, '위치 권한이 필요합니다.');
      }
      return false;
    }
  }

  // 여기까지 오면 WhenInUse(앱 사용 중에만 권한 허용)는 확보됨
  // 이미 '항상 허용'을 false로 설정했으면 그냥 지나감
  // 아직 안했다면 물어보기
  if (!needAlways) return true;

  // Always가 필요한 경우: 바로는 요청 불가 → WhenInUse 승인 뒤에만 가능
  // 플랫폼/OS 버전에 따라 Always가 “While Using 유지” vs “항상 허용” 팝업으로 나타남
  var alwaysStatus = await always.status;

  if (alwaysStatus.isGranted) return true;

  // Android/iOS 공통: 요청 시도
  final reqAlways = await always.request();

  if (reqAlways.isGranted) {
    return true;
  } else if (reqAlways.isPermanentlyDenied) {
    final go = await _showGoToSettingsDialog(context, reason: '항상 허용 권한이 영구 거절되었습니다. 설정에서 \'항상 허용\'으로 변경해 주세요.');
    if (go) await openAppSettings();                                                        // 사용자가 '설정으로 이동'-> true라 답하면 세팅을 열어줌 
    return false;
  } else {
    // 사용자가 "앱 사용 중만 유지" 선택
    _toast(context, '현재는 앱 사용 중에만 위치 접근이 허용되어 일부 기능이 제한될 수 있어요.');      // 사용자가 '설정으로 이동'-> false 시 사용 제한 메세지
    return false;
  }
}



/* 
 * - 권한 필요할 때 설정으로 이동할 수 있는 dialog 띄움
 * - [권한 거부] 했을 때 서비스 이용이 제한될 수 있음을 toast로 알림 
*/

Future<bool> _showGoToSettingsDialog(BuildContext context, {required String reason}) async {
  return await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('권한이 필요합니다'),
      content: Text(reason),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('설정으로 이동')),
      ],
    ),
  ) ?? false;
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}