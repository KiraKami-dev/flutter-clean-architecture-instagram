import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:instagram/core/functions/compress_image.dart';
import 'package:instagram/presentation/customPackages/crop_image/crop_image.dart';
import 'package:instagram/presentation/customPackages/crop_image/crop_options.dart';
import 'package:instagram/presentation/pages/profile/create_post_page.dart';
import 'package:instagram/presentation/pages/profile/custom_gallery_page/camera_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

enum SelectedPage { left, center, right }

class CustomGalleryDisplay extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CustomGalleryDisplay({Key? key, required this.cameras})
      : super(key: key);

  @override
  CustomGalleryDisplayState createState() => CustomGalleryDisplayState();
}

class CustomGalleryDisplayState extends State<CustomGalleryDisplay>
    with TickerProviderStateMixin {
  late TabController tabController = TabController(length: 2, vsync: this);
  bool neverScrollPhysics = false;
  ValueNotifier<bool> clearVideoRecord = ValueNotifier(false);
  ValueNotifier<bool> redDeleteText = ValueNotifier(false);
  SelectedPage selectedPage = SelectedPage.left;
  late Future<void> initializeControllerFuture;
  final cropKey = GlobalKey<CropState>();
  final List<FutureBuilder<Uint8List?>> _mediaList = [];
  late CameraController controller;
  bool showDeleteText = false;
  bool selectedVideo = false;
  Uint8List? selectedImage;
  bool shrinkWrap = false;
  List<Uint8List> multiSelectedImage = [];
  int selectedPaged = 0;
  bool? primary;
  bool remove = false;
  bool? stopScrollTab;
  int currentPage = 0;
  bool initial = true;
  late int lastPage;
  File? _lastCropped;

  @override
  void didUpdateWidget(CustomGalleryDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
      enableAudio: true,
    );
    initializeControllerFuture = controller.initialize();
    _fetchNewMedia();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    _lastCropped?.delete();
    super.dispose();
  }

  bool _handleScrollEvent(ScrollNotification scroll) {
    if (scroll.metrics.pixels / scroll.metrics.maxScrollExtent > 0.33) {
      if (currentPage != lastPage) {
        _fetchNewMedia();
        return true;
      }
    }
    return false;
  }

  _fetchNewMedia() async {
    lastPage = currentPage;
    var result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(onlyAll: true);
      List<AssetEntity> media =
          await albums[0].getAssetListPaged(page: currentPage, size: 60);
      List<FutureBuilder<Uint8List?>> temp = [];
      List<Uint8List?> imageTemp = [];
      for (int i = 0; i < media.length; i++) {
        FutureBuilder<Uint8List?> value = lowQualityImage(media, i);
        temp.add(value);
        Uint8List? image = await value.future;
        imageTemp.add(image);
      }

      setState(() {
        _mediaList.addAll(temp);
        allImages.addAll(imageTemp);
        currentPage++;
      });
    } else {
      PhotoManager.openSetting();
    }
  }

  List<Uint8List?> allImages = [];

  bool multiSelectionMode = false;
  FutureBuilder<Uint8List?> lowQualityImage(List<AssetEntity> media, int i) {
    Map m = {};
    FutureBuilder<Uint8List?> futureBuilder = FutureBuilder(
      future: media[i].thumbnailDataWithSize(const ThumbnailSize(1000, 1000)),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Uint8List? image = snapshot.data;
          if (image != null) {
            m["image"] = image;
            return Container(
              color: Colors.grey,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Image.memory(
                      image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (media[i].type == AssetType.video)
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 5, bottom: 5),
                        child: Icon(
                          Icons.videocam,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
        }
        return Container();
      },
    );
    m["future"] = futureBuilder;
    return futureBuilder;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scroll) {
        return _handleScrollEvent(scroll);
      },
      child: defaultTabController(),
    );
  }

  Widget tapBarMessage(bool isThatDeleteText) {
    Color deleteColor =
        redDeleteText.value ? Colors.red : Theme.of(context).focusColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (!redDeleteText.value) {
                redDeleteText.value = true;
              } else {
                clearVideoRecord.value = true;
                showDeleteText = false;
                redDeleteText.value = false;
              }
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isThatDeleteText)
                Icon(Icons.arrow_back_ios_rounded,
                    color: deleteColor, size: 15),
              Text(
                  isThatDeleteText
                      ? "DELETE"
                      : "The limit is 10 photo or videos.",
                  style: TextStyle(
                      fontSize: 14,
                      color: deleteColor,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  replacingDeleteWidget(bool showDeleteText) {
    setState(() {
      this.showDeleteText = showDeleteText;
    });
  }

  moveToVideo() {
    selectedPaged = 2;
    setState(() {
      selectedPage = SelectedPage.right;
      tabController.animateTo(1);
      selectedVideo = true;
      stopScrollTab = true;
      remove = true;
    });
  }

  DefaultTabController defaultTabController() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  dragStartBehavior: DragStartBehavior.start,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    CustomScrollView(
                      slivers: [
                        sliverAppBar(),
                        sliverSelectedImage(),
                        sliverGridView(),
                      ],
                    ),
                    CustomCameraDisplay(
                      cameras: widget.cameras,
                      controller: controller,
                      initializeControllerFuture: initializeControllerFuture,
                      replacingTabBar: replacingDeleteWidget,
                      clearVideoRecord: clearVideoRecord,
                      redDeleteText: redDeleteText,
                      moveToVideoScreen: moveToVideo,
                      selectedVideo: selectedVideo,
                    ),
                  ],
                ),
              ),
              if (multiSelectedImage.length < 10) ...[
                Visibility(
                  visible: !multiSelectionMode,
                  child: AnimatedSwitcher(
                      duration: const Duration(seconds: 1),
                      switchInCurve: Curves.easeIn,
                      child: showDeleteText ? tapBarMessage(true) : tabBar()),
                ),
              ] else ...[
                tapBarMessage(false)
              ],
            ],
          ),
        ),
      ),
    );
  }

  centerPage(
      {required bool isThatVideo,
      required int numPage,
      required SelectedPage selectedPage}) {
    selectedPaged = numPage;
    setState(() {
      selectedPage = selectedPage;
      tabController.animateTo(numPage);
      selectedVideo = isThatVideo;
      stopScrollTab = isThatVideo;
      remove = isThatVideo;
    });
  }

  Widget tabBar() {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Row(
          children: [
            Expanded(
              child: TabBar(
                controller: tabController,
                unselectedLabelColor: Colors.grey,
                labelColor:
                    selectedVideo ? Colors.grey : Theme.of(context).focusColor,
                indicatorColor: !selectedVideo
                    ? Theme.of(context).focusColor
                    : Colors.transparent,
                labelPadding: const EdgeInsets.all(13),
                tabs: [
                  GestureDetector(
                    onTap: () {
                      centerPage(
                          isThatVideo: false,
                          numPage: 0,
                          selectedPage: SelectedPage.left);
                    },
                    child: const Text("GALLERY",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  GestureDetector(
                    onTap: () {
                      centerPage(
                          isThatVideo: false,
                          numPage: 1,
                          selectedPage: SelectedPage.center);
                    },
                    child: const Text("PHOTO",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                selectedPaged = 2;
                setState(() {
                  tabController.animateTo(1);
                  selectedPage = SelectedPage.right;
                  selectedVideo = true;
                  stopScrollTab = true;
                  remove = true;
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14.0, horizontal: 40),
                child: Text("VIDEO",
                    style: TextStyle(
                        fontSize: 14,
                        color: selectedVideo
                            ? Theme.of(context).focusColor
                            : Colors.grey,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
        Visibility(
          visible: remove,
          child: AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
              onEnd: () {
                if (selectedPage != SelectedPage.right) {
                  setState(() {
                    remove = false;
                  });
                }
              },
              left: selectedPage == SelectedPage.left
                  ? 0
                  : (selectedPage == SelectedPage.center ? 120 : 240),
              child: Container(
                  height: 2,
                  width: 120,
                  color: Theme.of(context).primaryColor)),
        ),
      ],
    );
  }

  SliverAppBar sliverAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).primaryColor,
      floating: true,
      stretch: true,
      snap: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.clear_rounded,
            color: Theme.of(context).focusColor, size: 30),
        onPressed: () {
          Navigator.of(context).maybePop();
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_forward_rounded,
              color: Colors.blue, size: 30),
          onPressed: () async {
            if (multiSelectedImage.isEmpty) {
              Uint8List? image = selectedImage;
              if (image != null) {
                final tempDir = await getTemporaryDirectory();
                File selectedImageFile =
                    await File('${tempDir.path}/image.png').create();
                selectedImageFile.writeAsBytesSync(image);
                File? croppedImage = await cropImage(selectedImageFile);
                File? finalImage = await compressImage(croppedImage!);
                if (finalImage != null) {
                  await Navigator.of(context, rootNavigator: true).push(
                      CupertinoPageRoute(
                          builder: (context) => CreatePostPage(
                              selectedFile: finalImage,
                              isThatImage: true,
                              aspectRatio: 360),
                          maintainState: false));
                }
              }
            } else {
              List<File> selectedImages = [];
              for (int i = 0; i < multiSelectedImage.length; i++) {
                final tempDir = await getTemporaryDirectory();
                File selectedImageFile =
                    await File('${tempDir.path}/image.png').create();
                selectedImageFile.writeAsBytesSync(multiSelectedImage[i]);
                File? croppedImage = await cropImage(selectedImageFile);
                File? finalImage = await compressImage(croppedImage!);
                if (finalImage != null) {
                  selectedImages.add(finalImage);
                }
              }
              if (selectedImages.isNotEmpty) {
                await Navigator.of(context, rootNavigator: true).push(
                    CupertinoPageRoute(
                        builder: (context) => CreatePostPage(
                            selectedFile: selectedImages[0],
                            multiSelectedFiles: selectedImages,
                            isThatImage: true,
                            aspectRatio: 360),
                        maintainState: false));
              }
            }
          },
        ),
      ],
    );
  }

  Future<File?> cropImage(File imageFile) async {
    await ImageCrop.requestPermissions();
    final scale = cropKey.currentState!.scale;
    final area = cropKey.currentState!.area;
    if (area == null) {
      return null;
    }
    final sample = await ImageCrop.sampleImage(
      file: imageFile,
      preferredSize: (2000 / scale).round(),
    );

    final File file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );
    sample.delete();
    return file;
  }

  SliverAppBar sliverSelectedImage() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      floating: true,
      stretch: true,
      pinned: true,
      snap: true,
      backgroundColor: Theme.of(context).primaryColor,
      expandedHeight: 360,
      flexibleSpace: selectedImage != null
          ? Container(
              color: Theme.of(context).primaryColor,
              height: 360,
              width: double.infinity,
              child: Stack(
                children: [
                  Crop.memory(selectedImage!, key: cropKey),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            multiSelectionMode = !multiSelectionMode;
                            if (!multiSelectionMode) {
                              multiSelectedImage.clear();
                            }
                          });
                        },
                        child: Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              color: multiSelectionMode
                                  ? Colors.blue
                                  : const Color.fromARGB(199, 58, 58, 58),
                              border: Border.all(
                                color: const Color.fromARGB(45, 250, 250, 250),
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                                child: Icon(
                              Icons.copy,
                              color: Colors.white,
                              size: 17,
                            ))),
                      ),
                    ),
                  )
                ],
              ),
            )
          : Container(),
    );
  }

  stopScrolling(bool neverScroll) {
    setState(() {
      if (neverScroll) {
        shrinkWrap = true;
        neverScrollPhysics = true;
        primary = false;
      } else {
        shrinkWrap = false;
        neverScrollPhysics = false;
        primary = null;
      }
    });
  }

  bool selectionImageCheck(Uint8List image, {bool enableCopy = false}) {
    if (multiSelectedImage.contains(image) && selectedImage == image) {
      multiSelectedImage.remove(image);
      if (multiSelectedImage.isNotEmpty) {
        selectedImage = multiSelectedImage.last;
      }
      return true;
    } else {
      if (multiSelectedImage.length < 10) {
        if (!multiSelectedImage.contains(image)) {
          multiSelectedImage.add(image);
        }
        if (enableCopy) {
          selectedImage = image;
        }
      }
      return false;
    }
  }

  SliverGrid sliverGridView() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 1.7,
        mainAxisSpacing: 1.5,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          FutureBuilder<Uint8List?> mediaList = _mediaList[index];
          Uint8List? image = allImages[index];
          if (image != null) {
            bool imageSelected = multiSelectedImage.contains(image);
            if (index == 0 && selectedImage == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  selectedImage = image;
                });
              });
            }
            return Stack(
              children: [
                gestureDetector(image, index, mediaList),
                if (selectedImage == image)
                  GestureDetector(
                    child: gestureDetector(image, index, blurContainer()),
                  ),
                Visibility(
                  visible: multiSelectionMode,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          height: 25,
                          width: 25,
                          decoration: BoxDecoration(
                            color: imageSelected
                                ? Colors.blue
                                : const Color.fromARGB(115, 222, 222, 222),
                            border: Border.all(
                              color: Colors.white,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: imageSelected
                              ? Center(
                                  child: Text(
                                  "${multiSelectedImage.indexOf(image) + 1}",
                                  style: const TextStyle(color: Colors.white),
                                ))
                              : Container(),
                        )),
                  ),
                ),
              ],
            );
          } else {
            return Container();
          }
        },
        childCount: _mediaList.length,
      ),
    );
  }

  Container blurContainer() {
    return Container(
      width: double.infinity,
      color: const Color.fromARGB(184, 234, 234, 234),
      height: double.maxFinite,
    );
  }

  GestureDetector gestureDetector(Uint8List image, int index, Widget child) {
    return GestureDetector(
        onTap: () {
          setState(() {
            if (multiSelectionMode) {
              bool close = selectionImageCheck(image);
              if (close) return;
            }
            selectedImage = image;
          });
        },
        onLongPress: () {
          setState(() {
            if (!multiSelectionMode) {
              multiSelectionMode = true;
            }
          });
        },
        onLongPressUp: () {
          setState(() {
            selectionImageCheck(image, enableCopy: true);
          });
        },
        child: child);
  }
}
