import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/models/tag_model.dart';

// 태그 리스트 섹션 모델 (자바에서 붕어빵 틀 같은 역할)
class TagSection{
  final String id;          // 태그 아이디
  final String title;       // 태그 제목
  final List<String> tags;  // 태그 리스트
  final bool isMultiSelect; // 다중 선택 가능 여부

  const TagSection({
    required this.id,
    required this.title,
    required this.tags,
    this.isMultiSelect = true, // 기본값은 다중 선택 가능(FilterChip 위젯 사용)
  });
}

// 붕어빵들
const List<TagSection> tagSections = [ 
  TagSection(
    id: 'brand_category',
    title: '카메라 제조사',
    tags: ['sony', 'canon', 'panasonic', 'olympus', 'leica', 'pentax', 'minolta', 'nikon', 'fujifilm', 'kodak'],
    isMultiSelect: false, // 단일 선택 (ChoiceChip 위젯 사용)
  ),
  TagSection(
    id: 'camera_type',
    title: '카메라 종류',
    tags: ['미러리스', 'DSLR', '폴라로이드 카메라', '토이 카메라', '스마트폰 카메라', '35mm 필름 카메라', '중형 필름 카메라', '대형 필름 카메라', '하프 카메라'],
    isMultiSelect: false, 
  ),
  TagSection(
    id: 'sensor_type',
    title: '센서 종류',
    tags: ['풀프레임', 'APS-C', '마이크로포서드', '1인치'],
    isMultiSelect: false,
  ),
  TagSection(
    id: 'effective_megapixels',
    title: '유효 화소수',
    tags: ['1000만 화소 이하', '1000만~2000만 화소', '2000만~3000만 화소', '3000만~4000만 화소', '4000만 화소 이상'],
    isMultiSelect: false, 
  ),
  TagSection(
    id: 'film_brand',
    title: '필름 브랜드',
    tags: ['코닥', '후지필름', '일렉트로닉이미징코리아(에코플러스)', '로모그래피', '아그파', '페이머스그레이스'],
    isMultiSelect: false, 
  ),

  TagSection(id: 'subject', title: '주제', tags: ['인물사진', '풍경사진', '여행사진', '동물사진', '식물사진', '우주사진','기타']),
  TagSection(id: 'portrait', title: '인물사진', tags: ['셀카', '혼자', '가족사진', '커플사진', '단체사진', '정면', '옆모습']),
  TagSection(id: 'landscape', title: '풍경사진', tags: ['야경', '일출/일몰', '바다/호수', '산/계곡', '도시/건축물', '농촌', '정글', '사막']),
  TagSection(id: 'nature', title: '자연사진', tags: ['동물', '식물', '곤충']),
  TagSection(id: 'travel', title: '여행사진', tags: ['국내여행', '해외여행', '문화유산', '축제/행사']),
  TagSection(id: 'street', title: '스트리트사진', tags: ['일상', '스냅사진', '도시생활']),
  TagSection(id: 'macro', title: '매크로사진', tags: ['꽃', '곤충', '작은물체']),
];


class TagSelectionScreen extends StatefulWidget {
  const TagSelectionScreen({super.key, required this.initialState});
  //final List<String> selectedTags; // 선택된 태그 리스트를 전달받음
  final SelectedTagState initialState; // 선택된 태그 상태 관리 모델을 전달받음

  @override
  State<TagSelectionScreen> createState() => _TagSelectionScreenState();  
}


class _TagSelectionScreenState extends State<TagSelectionScreen> {

  // 단일 선택 태그 저장용 맵 (섹션 아이디로 -> 선택된 태그 검색 _singleSelectedTags[section.id] == tag)
  final Map<String, String> _singleSelectedTags = {};

  // 다중 선택 태그 저장용 맵 (섹션 아이디 -> 선택된 태그 리스트)
  final Map<String, Set<String>> _multiSelectedTags = {};

  // 태그 상태 모델 초기화
  @override
  void initState() {
    super.initState();
    // 초기 상태 복사(가변화)
    _singleSelectedTags.addAll(widget.initialState.singleTags); // 단일 선택 태그들 복사
    _multiSelectedTags.addAll(widget.initialState.multiTags.map((key, value) => MapEntry(key, Set<String>.from(value)))); // 다중 선택 태그들 복사 (Set도 복사)
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('태그 선택', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        scrolledUnderElevation: 0,
      ),

      // 화면의 본문 (태그 목록)
      body: SingleChildScrollView(                            // 내용이 많을 경우 스크롤 가능
        padding: const EdgeInsets.all(16.0),                  // 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,       // 왼쪽 정렬
          children: [
            for (var section in tagSections) ...[             // 각 섹션에 대해
              // 섹션 제목
              Text(section.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
              const SizedBox(height: 8.0),   

              // 공통 디자인
              Theme(
                data: Theme.of(context).copyWith(
                  chipTheme: ChipThemeData(                                         // 칩 위젯의 테마 설정
                    backgroundColor: Colors.white,                           // 기본 배경색
                    selectedColor: const Color.fromARGB(255, 18, 18, 18),         // 선택된 칩의 배경색
                    labelStyle: const TextStyle(color: Colors.black),             // 기본 텍스트 스타일
                    secondaryLabelStyle: const TextStyle(color: Colors.white),    // 선택된 칩의 텍스트 스타일
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // 칩 내부 패딩
                    shape: RoundedRectangleBorder(       // 칩의 모양 설정 (둥근 모서리)
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ), 

                // 태그
                child: Wrap(                         // 태그들을 감싸는 위젯 (자동 줄바꿈)           
                  spacing: 8.0,                      // 태그들 사이 가로 간격
                  runSpacing: 0.0,                   // 태그들 사이 세로 간격

                  children: section.tags.map((tag) {           // 각 태그에 대해
                    final isSelected = section.isMultiSelect   // 이미 선택된 태그인지 여부 -> isSelected는 bool 타입
                      ? (_multiSelectedTags[section.id]?.contains(tag) ?? false) // 다중 선택일 때, _multiSelectedTags[section.id]?.은 null이 아닐때만 contains(tag) 호출, null이면 null반환. 그리고 ?? false에 의해 false 반환
                      : (_singleSelectedTags[section.id] == tag);                // 단일 선택

                    return section.isMultiSelect 
                      ? FilterChip( // 다중 선택용 칩
                          label: Text(tag),
                          selected: isSelected,   // 현재 선택 상태
                          labelStyle: TextStyle(  // 선택 상태에 따른 텍스트 스타일
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                          onSelected: (selecte) { // 선택 상태 변경 시 호출
                            setState(() {
                              if (selecte) { 
                                _multiSelectedTags.putIfAbsent(section.id, () => <String>{}).add(tag); // 맵에 해당 섹션 아이디가 없으면 빈 집합을 추가하고, 그 집합에 태그 추가
                              } else {            // 선택 해제
                                _multiSelectedTags[section.id]?.remove(tag);
                                if (_multiSelectedTags[section.id]?.isEmpty ?? true) {  // 선택된 태그가 없으면 맵에서 해당 섹션 아이디 제거. 쉽게 하면 _multiSelectedTags[section.id] == null || _multiSelectedTags[section.id]! == isEmpty
                                  _multiSelectedTags.remove(section.id);                // _multiSelectedTags[section.id]?가 null이면 null, null이 아니면 isEmpty의 결과값 반환
                                }                                                       // ?? true에 의해 null이면 true, true/false면 그 값 반환
                              }
                            });
                          },
                        )
                      : ChoiceChip( // 단일 선택용 칩
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selecte) {
                            setState(() {
                              if (selecte) {
                                _singleSelectedTags[section.id] = tag;  // 태그 추가
                              } else {
                                _singleSelectedTags.remove(section.id); // 태그 제거
                              }
                            });
                          },
                        );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8.0), // 섹션 간 간격
              const Divider(),             // 구분선
              const SizedBox(height: 8.0), // 섹션 간 간격
            ],

          ],
        ),
      ),

      bottomNavigationBar: Padding( // 하단의 완료 버튼
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // 선택된 태그들을 sell_write 화면으로 전달
            final result = SelectedTagState( // 선택된 태그 상태 모델 생성
              singleTags: Map<String, String>.from(_singleSelectedTags),
              multiTags: _multiSelectedTags.map((key, value) => MapEntry(key, Set<String>.from(value))),
            );
            Navigator.pop(context, result); // 이전 화면으로 돌아가면서 선택된 태그 리스트 전달
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8BC34A),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            minimumSize: const Size(double.infinity, 50), // 가로 꽉 채우기
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text('선택 완료'),
        ),
      ),
    );
  }
}