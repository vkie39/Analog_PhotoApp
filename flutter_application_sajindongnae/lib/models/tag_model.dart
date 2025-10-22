import 'package:flutter/material.dart';


/* 선택된 태그 상태 관리 모델
* 선택된 태그를 읽기전용으로 보존하는 역할
* sell_write, buy_write, tag_select 등에서 사용
*/

class SelectedTagState{   
  final Map<String, String> singleTags;              // 섹션 id를 통해 태그에 접근
  final Map<String, Set<String>> multiTags;

  // 생성자
  SelectedTagState({
    Map<String, String>? singleTags,
    Map<String, Set<String>>? multiTags,
  })                                                 
  : singleTags = Map.unmodifiable(singleTags ?? {}), // 선택된 태그들을 불변 맵으로 초기화 (초기값은 빈 맵, null일 경우 {}, 읽기 전용)
    multiTags = Map.unmodifiable(multiTags ?? {}).map((key, value) => MapEntry(key, Set.unmodifiable(value))); // Set도 불변으로 만듦


  // Map을 수정하기 위한 메서드
  SelectedTagState copyWith({                        // copywith는 기존 상태를 기반으로 일부값만 바꿔 새로운 selectedTagState 객체를 만듦
    Map<String, String>? singleTags,
    Map<String, Set<String>>? multiTags,
  }) {
    return SelectedTagState(
      singleTags: singleTags ?? this.singleTags,     // 새로운 값이 주어지면  새로운  singleTags로, 아니면 기존값 유지
      multiTags: multiTags ?? this.multiTags,
    );
  }
}

/*
 * 태그 데이터 흐름
 * 
 * SellWriteScreen(_selectedTagState)
 *    └─ [열기] _openTagSelector() → Navigator.push(
 *         TagSelectionScreen(initialState: 현재 _selectedTagState)
 *       )
 *          └─ [tag_select.dart] initState():
 *             initialState의 맵들을 로컬 가변맵(_singleSelectedTags, _multiSelectedTags)으로 복사
 *          └─ [사용자 선택] ChoiceChip/FilterChip으로 로컬 가변맵 수정
 *          └─ [완료] '선택 완료' 버튼 → SelectedTagState 로 새로 포장 → Navigator.pop(result)
 *    └─ [복귀] await result → setState(() => _selectedTagState = result)
 *    └─ tagList getter가 최신 선택 태그를 계산해 UI(Chip 목록, 제출 등)에 사용
 */