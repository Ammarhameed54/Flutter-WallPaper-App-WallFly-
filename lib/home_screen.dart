import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List data = [];
  TextEditingController searchImage = TextEditingController();
  String? selectedImageUrl;

  final List<String> categories = [
    'arch',
    'movie',
    'travel',
    'animal',
    'food',
    'sports',
    'nature'
  ];

  @override
  void initState() {
    super.initState();
    getPhoto(categories[0]);
  }

  getPhoto(search) async {
    setState(() {
      data = [];
    });

    try {
      final url = Uri.parse(
          "https://api.unsplash.com/search/photos/?client_id=Your_Unsplash_APi_ACCESS_KEY&query=$search&per_page=30");
      var response = await http.get(url);
      var result = jsonDecode(response.body);
      setState(() {
        data = result['results'];
      });
      print(data);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> downloadImage(String imageUrl) async {
    try {
      // Get image data
      var response = await http.get(Uri.parse(imageUrl));
      var bytes = response.bodyBytes;

      // Get temporary directory
      var tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;

      // Create temporary file
      File file =
          File('$tempPath/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);

      // Save to gallery
      await GallerySaver.saveImage(file.path, albumName: 'MyAppImages');

      // Delete temporary file
      file.delete();

      // Show success message
      print('Image saved to gallery');
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 213, 213, 213),
      body: Stack(
        children: [
          ListView(
            children: [
              const SizedBox(
                height: 20,
              ),
              topRow(),
              searchBar(),
              const Center(
                child: Text("Categories have a look at",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(
                height: 20,
              ),
              horizontalBuilder(),
              verticalBuilder(),
            ],
          ),

          // Download Button
          if (selectedImageUrl != null)
            Positioned(
              bottom: 80,
              right: 80,
              child: ElevatedButton(
                onPressed: () {
                  downloadImage(selectedImageUrl!);
                },
                child: const Text("Download"),
              ),
            ),
        ],
      ),
    );
  }

  // Top Row
  Widget topRow() {
    return Row(
      children: [
        const SizedBox(
          width: 20,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset(
            "images/nature.jpg",
            fit: BoxFit.cover,
            height: 50,
            width: 50,
          ),
        ),
        const SizedBox(
          width: 50,
        ),
        RichText(
            text: const TextSpan(children: [
          TextSpan(
              text: "Wall",
              style: TextStyle(
                  color: Colors.blue,
                  fontSize: 40,
                  fontWeight: FontWeight.bold)),
          TextSpan(
              text: "Fly",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 40,
                  fontWeight: FontWeight.bold))
        ]))
      ],
    );
  }

  // Textfield Container
  Container searchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: searchImage,
              decoration: const InputDecoration(
                  hintText: "Search Images(nature, animal)....",
                  border: InputBorder.none),
            ),
          )),
          IconButton(
              onPressed: () {
                if (searchImage.text.isNotEmpty) {
                  getPhoto(searchImage.text);
                }
              },
              icon: const Icon(
                Icons.search,
                color: Colors.blue,
                size: 30,
              ))
        ],
      ),
    );
  }

  // HorizontalBuilder (Categories)
  Container horizontalBuilder() {
    return Container(
      height: 70,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                getPhoto(categories[index]);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                      image: AssetImage('images/${categories[index]}.jpg'),
                      fit: BoxFit.cover),
                ),
                child: Center(
                  child: Text(
                    categories[index],
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                ),
              ),
            );
          }),
    );
  }

  // Vertical Builder
  Widget verticalBuilder() {
    return data.isNotEmpty
        ? MasonryGridView.count(
            itemCount: data.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            itemBuilder: (context, index) {
              double ht = index % 2 == 0 ? 200 : 100;
              String imageUrl = data[index]['urls']['regular'];
              return Padding(
                padding: const EdgeInsets.all(10),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedImageUrl = imageUrl;
                    });
                  },
                  child: Stack(
                    children: [
                      InstaImageViewer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            imageUrl,
                            height: ht,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
        : Container(
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
  }
}
