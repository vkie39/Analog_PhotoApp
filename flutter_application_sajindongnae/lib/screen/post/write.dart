import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/post_service.dart';
import '../../models/post_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class WriteScreen extends StatefulWidget {
  final String category;

  const WriteScreen({super.key, required this.category});
  
  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final List<String> categoryList = ['자유', '카메라추천', '피드백'];
  late String selectedCategory;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose(); 
  }
  

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context); // 뒤로가기
            },
          ),
          title: Text(
            '글쓰기',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () async { // firestore에 저장
                final title = titleController.text.trim();     // 제목
                final content = contentController.text.trim(); // 내용
                final category = selectedCategory;             // 카테고리

                if(title.isEmpty){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('제목을 입력해주세요')),
                    );
                }
                else if(content.isEmpty){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('내용을 입력해주세요')),
                    );
                }

                final newPost = PostModel(
                  postId: const Uuid().v4(), 
                  userId: '임시유저ID', // 로그인된 사용자 ID로 수정 필요요
                  nickname: '용용선생', 
                  profileImageUrl: '',  // 프로필 이미지 URL
                  category: category,
                  likeCount: 0, // 기본 0
                  commentCount: 0,
                  timestamp: DateTime.now(),
                  title: title,
                  content: content,
                  imageUrl: null, // 이미지 업로드 기능이 추가되면 수정
                );

                try {
                  await PostService.createPost(newPost);
                  Navigator.pop(context); // 업로드 완료 후 뒤로가기
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('게시글 등록에 실패했어요. 다시 시도해주세요.')),
                  );
                }



              },
              child: const Text(
                '등록',
                style: TextStyle(
                  color: Colors.green, // 완료 텍스트 색상 (예시로 연두 계열)
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Container(
          color: const Color.fromARGB(255, 255, 255, 255),
          child: SingleChildScrollView( // 스크롤뷰로 만듦듦
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:  CrossAxisAlignment.start, // 왼쪽 정렬
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromARGB(255, 203, 227, 167),
                    ),
                    borderRadius: BorderRadius.circular(18) 
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true,
                      value: selectedCategory,
                      items: categoryList.map((String value){ // 드롭 다운 항목 생성
                        return DropdownMenuItem<String>(
                          value: value, // value는 실제값, text는 유저에게 보여지는 라벨벨
                          child: Text(value, style: const TextStyle(fontSize: 12, color:Colors.black)),
                          );
                      }).toList(),
                      onChanged: (String? newValue){
                        setState(() {
                          selectedCategory = newValue!;
                        });
                      },
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        height: 40,
                        width: 110,
                      ),
                      dropdownStyleData: DropdownStyleData(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        offset: const Offset(0, -5),
                      ),
                      iconStyleData:  const IconStyleData(
                        icon: Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        iconEnabledColor: Colors.black,
                      ),
                      menuItemStyleData:  const MenuItemStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        height: 40,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height:20),

                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: '제목을 입력해주세요',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),

                const Divider(),
                
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    hintText: '내용을 작성해주세요',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 24),

              ],
            )
          )
        ),
      ),
    );
  }
}
