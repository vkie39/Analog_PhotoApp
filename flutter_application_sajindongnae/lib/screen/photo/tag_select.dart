import 'package:flutter/material.dart';
import 'package:flutter_application_sajindongnae/models/tag_model.dart';

/*
* 태그선택 화면
* - 태그 섹션 별로 단일 선택과 다중 선택을 지원
* - 선택된 태그들은 sell_write, photo_sell 화면으로 전달
* - 태그 섹션과 태그들은 TagSection 모델과 tagSections 리스트로 관리
* - 단일 선택은 ChoiceChip, 다중 선택은 FilterChip 위젯 사용
* - 선택된 태그들은 SelectedTagState 모델로 관리
* - 선택된 태그 상태는 _singleSelectedTags, _multiSelectedTags 맵으로 관리
* - photo_sell 화면에서 들어올 땐 foreMultiSelect가 true로 선택되어 다중 선택 모드로 진입 (검색 기능이기 때문)
*/


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
    this.isMultiSelect = false, // 기본값은 다중 선택 불가(ChoiceChip 위젯 사용)
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
  TagSection(
    id: 'iso',
    title: 'ISO(감도)',
    tags: [
      'ISO 100 이하',
      'ISO 100 ~ 400',
      'ISO 400 ~ 800',
      'ISO 800 ~ 1600',
      'ISO 1600 ~ 3200',
      'ISO 3200 이상',
    ],
    isMultiSelect: false,
  ),
  TagSection(
    id: 'shutter_speed',
    title: '셔터스피드',
    tags: [
      '1/8000초',
      '1/4000초',
      '1/2000초',
      '1/1000초',
      '1/500초',
      '1/250초',
      '1/125초',
      '1/60초',
      '1/30초',
      '1/15초',
      '1/8초',
      '1/4초',
      '1/2초',
      '1초 이상(장노출)',
    ],
    isMultiSelect: false,
  ),
  TagSection(
    id: 'aperture',
    title: '조리개값(Aperture)',
    tags: [
      'f/1.2',
      'f/1.4',
      'f/1.8',
      'f/2.0',
      'f/2.8',
      'f/4.0',
      'f/5.6',
      'f/8.0',
      'f/11',
      'f/16',
      'f/22',
    ],
    isMultiSelect: false,
  ),

TagSection(
  id: 'subject',
  title: '주제',
  tags: [
    '인물', '풍경', '여행', '자연', '동물', '식물',
    '도시', '음식', '패션', '스포츠', '우주/천체',
    '예술/전시', '야간촬영', '건축물', '매크로',
    '라이프스타일', '길거리', '제품사진', '기타',
  ],
),

TagSection(
  id: 'portrait',
  title: '인물사진',
  tags: [
    '셀카',
    '프로필사진',
    '가족사진',
    '커플사진',
    '단체사진',
    '아이/아동',
    '시니어',
    '정면샷',
    '측면샷',
    '전신사진',
    '상반신',
    '감성사진',
    '패션/룩북',
    '웨딩/스냅',
    '행사/파티',
    '스튜디오 촬영',
    '야외 촬영',
  ],
),
TagSection(
  id: 'landscape',
  title: '풍경사진',
  tags: [
    '야경',
    '일출',
    '일몰',
    '바다',
    '호수',
    '강/하천',
    '산',
    '계곡',
    '초원',
    '숲/정글',
    '사막',
    '도시 스카이라인',
    '건축물 풍경',
    '비/눈 풍경',
    '안개/구름',
    '별/천체 풍경',
  ],
),

TagSection(
  id: 'nature',
  title: '자연사진',
  tags: [
    '동물',
    '식물',
    '곤충',
    '꽃',
    '나무',
    '새',
    '야생동물',
    '파충류/양서류',
    '수중 생물',
    '버섯/균류',
  ],
),

TagSection(
  id: 'travel',
  title: '여행사진',
  tags: [
    '국내여행',
    '해외여행',
    '도시여행',
    '자연여행',
    '문화유산',
    '유적지',
    '전통시장',
    '축제',
    '행사/공연',
    '카페/맛집',
    '랜드마크',
  ],
),
TagSection(
  id: 'street',
  title: '스트리트사진',
  tags: [
    '일상',
    '길거리 스냅',
    '도시생활',
    '인파/군중',
    '거리패션',
    '상점/간판',
    '거리예술',
    '야간 스냅',
    '주행/도로',
    '시장/골목',
  ],
),

TagSection(
  id: 'macro',
  title: '매크로사진',
  tags: [
    '꽃',
    '곤충',
    '작은 물체',
    '보석/악세서리',
    '텍스처',
    '물방울',
    '눈송이',
    '음식 접사',
    '기계/부품',
  ],
),

TagSection(
  id: 'environment',
  title: '촬영 환경',
  tags: [
    '실내',
    '실외',
    '자연광',
    '인공조명',
    '역광',
    '정면광',
    '측광',
    '흐린 날',
    '맑은 날',
    '비 오는 날',
    '눈 오는 날',
    '안개/구름',
    '야간 촬영',
    '황금시간대(Golden Hour)',
    '매직아워',
    '스튜디오',
    '카페/실내공간',
    '도시/거리',
    '자연/야외',
  ],
),



  ];

/// 1. 재사용 가능한 태그 선택 화면 위젯
/// - initialState : 초기 선택된 태그 상태 (이전 화면에서 전달)
/// - sections : 태그 섹션 리스트 (기본값은 위에서 정의한 tagSections)
/// - forceMultiSelect : 다중 선택 강제 여부 
/// - title : 화면 제목 ('태그 검색'으로도 설정될 수 있음)
/// - 선택된 태그들은 SeletedTagState 모델로 관리하여 이전 화면으로 전달
/// --------------------------------------------------------------

class TagSelectionScreen extends StatefulWidget {
  const TagSelectionScreen({
    super.key,
    required this.initialState,
    this.sections = tagSections,
    this.forceMultiSelect = false,
    this.title = '태그 선택',
    this.showAppBar = true,
  });

  final SelectedTagState initialState;
  final List<TagSection> sections;
  final bool forceMultiSelect;
  final String title;
  final bool showAppBar;

  @override
  State<TagSelectionScreen> createState() => _TagSelectionScreenState();
}

class _TagSelectionScreenState extends State<TagSelectionScreen> {
  final Map<String, String> _singleSelectedTags = {};
  final Map<String, Set<String>> _multiSelectedTags = {};

  @override
  void initState() {
    super.initState();
    _singleSelectedTags.addAll(widget.initialState.singleTags);
    _multiSelectedTags.addAll(widget.initialState.multiTags.map(
      (key, value) => MapEntry(key, Set<String>.from(value)),
    ));
  }

  bool _isSelected(String sectionId, String tag, bool isMultiSelect) {
    if (isMultiSelect) {
      return _multiSelectedTags[sectionId]?.contains(tag) ?? false;
    } else {
      return _singleSelectedTags[sectionId] == tag;
    }
  }

  void _toggleSelection(
      String sectionId, String tag, bool isMultiSelect, bool selected) {
    setState(() {
      if (isMultiSelect) {
        if (selected) {
          _multiSelectedTags.putIfAbsent(sectionId, () => <String>{}).add(tag);
        } else {
          _multiSelectedTags[sectionId]?.remove(tag);
          if (_multiSelectedTags[sectionId]?.isEmpty ?? true) {
            _multiSelectedTags.remove(sectionId);
          }
        }
      } else {
        if (selected) {
          _singleSelectedTags[sectionId] = tag;
        } else {
          _singleSelectedTags.remove(sectionId);
        }
      }
    });
  }

  SelectedTagState _currentSelectedTagState() => SelectedTagState(
        singleTags: Map<String, String>.from(_singleSelectedTags),
        multiTags: _multiSelectedTags.map(
          (key, value) => MapEntry(key, Set<String>.from(value)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
                title: Text(
                widget.title, 
                style: TextStyle(
                  fontSize: 20,        
                  fontWeight: FontWeight.bold, 
                  color: Colors.black, 
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,
            )
          : null,
          backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in widget.sections) ...[
              Text(
                section.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: section.tags.map((tag) {
                  final isSelected = _multiSelectedTags[section.id]?.contains(tag) ?? false;

                  return FilterChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    backgroundColor: Colors.white,
                    selectedColor: Color(0xFFBBD18B),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _multiSelectedTags.putIfAbsent(section.id, () => <String>{}).add(tag);
                        } else {
                          _multiSelectedTags[section.id]?.remove(tag);
                          if (_multiSelectedTags[section.id]?.isEmpty ?? true) {
                            _multiSelectedTags.remove(section.id);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),


              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _currentSelectedTagState());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8BC34A),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('선택 완료'),
        ),
      ),
    );
  }
}
