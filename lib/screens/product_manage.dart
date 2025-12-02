import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shop_cutesy/utils/purple_box.dart';
import 'package:shop_cutesy/widgets/top_bar.dart';
import 'package:shop_cutesy/widgets/bottom_navigation.dart';

class ProductManage extends StatefulWidget {
  const ProductManage({super.key});

  @override
  State<ProductManage> createState() => _ProductManageState();
}

enum ViewMode { products, discounts, archives }

enum ArchiveSub { products, discounts }

class _ProductManageState extends State<ProductManage> {
  bool menuVisible = false;
  int bottomIndex = -1;

  List<DocumentSnapshot> productList = [];
  List<DocumentSnapshot> filteredList = [];

  List<DocumentSnapshot> discountList = [];
  List<DocumentSnapshot> filteredDiscountList = [];

  List<DocumentSnapshot> archivedProducts = [];
  List<DocumentSnapshot> archivedDiscounts = [];

  Set<String> selectedItems = {};
  TextEditingController searchC = TextEditingController();

  ViewMode viewMode = ViewMode.products;
  ArchiveSub archiveSub = ArchiveSub.products;

  @override
  void initState() {
    super.initState();
    searchC.addListener(_searchCurrent);
    fetchAll();
  }

  @override
  void dispose() {
    searchC.dispose();
    super.dispose();
  }

  Future<void> fetchAll() async {
    await expireDiscounts();
    await Future.wait([
      fetchProducts(),
      fetchDiscounts(),
      fetchArchivedProducts(),
      fetchArchivedDiscounts(),
    ]);
  }

  Future<void> fetchProducts() async {
    final snap = await FirebaseFirestore.instance.collection("products").get();
    setState(() {
      productList = snap.docs;
      if (viewMode == ViewMode.products) filteredList = List.from(productList);
    });
  }

  Future<void> fetchDiscounts() async {
    final snap = await FirebaseFirestore.instance.collection("discounts").get();
    setState(() {
      discountList = snap.docs;
      if (viewMode == ViewMode.discounts) {
        filteredDiscountList = List.from(discountList);
      }
    });
  }

  Future<void> fetchArchivedProducts() async {
    final snap = await FirebaseFirestore.instance
        .collection("archived_products")
        .get();
    setState(() {
      archivedProducts = snap.docs;
    });
  }

  Future<void> fetchArchivedDiscounts() async {
    final snap = await FirebaseFirestore.instance
        .collection("archived_discounts")
        .get();
    setState(() {
      archivedDiscounts = snap.docs;
    });
  }

  void _searchCurrent() {
    final query = searchC.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        if (viewMode == ViewMode.products)
          filteredList = List.from(productList);
        if (viewMode == ViewMode.discounts)
          filteredDiscountList = List.from(discountList);
      });
      return;
    }

    if (viewMode == ViewMode.products) {
      setState(() {
        filteredList = productList.where((doc) {
          final data = doc.data() as Map;
          final title = (data["title"] ?? "").toString().toLowerCase();
          final tag = (data["tag"] ?? "").toString().toLowerCase();
          return title.contains(query) || tag.contains(query);
        }).toList();
      });
    } else if (viewMode == ViewMode.discounts) {
      setState(() {
        filteredDiscountList = discountList.where((doc) {
          final data = doc.data() as Map;
          final tags = (data["tags"] ?? []).join(" ").toLowerCase();
          final pct = (data["percentage"] ?? "").toString().toLowerCase();
          return tags.contains(query) || pct.contains(query);
        }).toList();
      });
    }
  }

  void showProductForm({DocumentSnapshot? editDoc}) {
    bool isEdit = editDoc != null;
    Map data = isEdit ? editDoc!.data() as Map : {};

    TextEditingController titleC = TextEditingController(
      text: data["title"] ?? "",
    );
    TextEditingController priceC = TextEditingController(
      text: data["price"] ?? "",
    );
    TextEditingController qtyC = TextEditingController(
      text: data["quantity"] ?? "",
    );
    TextEditingController descC = TextEditingController(
      text: data["description"] ?? "",
    );
    TextEditingController categoryC = TextEditingController();
    TextEditingController tagC = TextEditingController(text: data["tag"] ?? "");
    TextEditingController discountC = TextEditingController(
      text: (data["discount"] ?? 0).toString(),
    );

    List<String> categories = isEdit
        ? List<String>.from(data["categories"] ?? [])
        : [];
    List<String> images = isEdit ? List<String>.from(data["images"] ?? []) : [];
    int totalSold = isEdit ? data["total_sold"] ?? 0 : 0;
    int productId = isEdit ? (data["product_id"] ?? 0) : 0;

    Future<void> fetchNextProductId() async {
      if (isEdit) return;
      final snap = await FirebaseFirestore.instance
          .collection("products")
          .orderBy("product_id", descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        productId = (snap.docs.first.data() as Map)["product_id"] + 1;
      } else {
        productId = 1;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadId() async {
              await fetchNextProductId();
              setDialogState(() {});
            }

            if (!isEdit && productId == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) => loadId());
            }

            Future<void> pickImage() async {
              if (images.length >= 3) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: bgPink,
                    title: const Text("Warning"),
                    content: const Text("Maximum 3 images allowed."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
                return;
              }
              PermissionStatus cameraStatus = await Permission.camera.request();
              PermissionStatus galleryStatus = await Permission.photos
                  .request();

              if (!cameraStatus.isGranted || !galleryStatus.isGranted) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: bgPink,
                    title: const Text("Permission"),
                    content: const Text(
                      "Please allow camera and gallery permissions.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
                return;
              }

              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) {
                  return SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text("Take Photo"),
                          onTap: () async {
                            Navigator.pop(context);
                            final file = await ImagePicker().pickImage(
                              source: ImageSource.camera,
                            );
                            if (file != null) {
                              final bytes = await File(file.path).readAsBytes();
                              images.add(base64Encode(bytes));
                              setDialogState(() {});
                            }
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo),
                          title: const Text("Pick from Gallery"),
                          onTap: () async {
                            Navigator.pop(context);
                            final file = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );
                            if (file != null) {
                              final bytes = await File(file.path).readAsBytes();
                              images.add(base64Encode(bytes));
                              setDialogState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            return AlertDialog(
              backgroundColor: bgPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(isEdit ? "Edit Product" : "Add Product"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 120,
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: List.generate(3, (index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: fieldPurple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: images.length > index
                                        ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.memory(
                                                  base64Decode(images[index]),
                                                  fit: BoxFit.cover,
                                                  width: 60,
                                                  height: 60,
                                                ),
                                              ),
                                              Positioned(
                                                right: 4,
                                                top: 4,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setDialogState(() {
                                                      images.removeAt(index);
                                                    });
                                                  },
                                                  child: const CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor: Colors.red,
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Center(
                                            child: Text(
                                              "Image ${index + 1}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  );
                                }),
                              ),
                            ),
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: fieldPurple,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      inputBox(titleC, "Product Title"),
                      const SizedBox(height: 8),
                      inputBox(priceC, "Price"),
                      const SizedBox(height: 8),
                      inputBox(qtyC, "Quantity"),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: fieldPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: descC,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: "Description (max 200 words)",
                            hintStyle: TextStyle(color: Colors.white),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: fieldPurple,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                controller: categoryC,
                                decoration: const InputDecoration(
                                  hintText: "Enter category",
                                  hintStyle: TextStyle(color: Colors.white),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (categoryC.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  categories.add(categoryC.text.trim());
                                  categoryC.clear();
                                });
                              }
                            },
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        children: categories
                            .map(
                              (c) => Chip(
                                label: Text(c),
                                onDeleted: () {
                                  setDialogState(() {
                                    categories.remove(c);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      inputBox(tagC, "Tag (single tag)"),
                      const SizedBox(height: 8),
                      inputBox(discountC, "Discount (%)"),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Sold: $totalSold"),
                          Text("Product ID: $productId"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (titleC.text.isEmpty ||
                        priceC.text.isEmpty ||
                        qtyC.text.isEmpty ||
                        images.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please fill required fields and add at least one image.",
                          ),
                        ),
                      );
                      return;
                    }
                    try {
                      final docData = {
                        "images": images,
                        "title": titleC.text,
                        "price": priceC.text,
                        "quantity": qtyC.text,
                        "description": descC.text,
                        "categories": categories,
                        "tag": tagC.text.trim(),
                        "discount": int.tryParse(discountC.text) ?? 0,
                      };

                      if (isEdit) {
                        await FirebaseFirestore.instance
                            .collection("products")
                            .doc(editDoc!.id)
                            .update(docData);
                      } else {
                        docData.addAll({
                          "total_sold": 0,
                          "product_id": productId,
                        });
                        await FirebaseFirestore.instance
                            .collection("products")
                            .add(docData);
                      }

                      Navigator.pop(context);
                      await fetchProducts();
                    } catch (e) {
                      print("ERROR saving product: $e");
                    }
                  },
                  child: Text(isEdit ? "Update" : "Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showDiscountForm({DocumentSnapshot? editDoc}) async {
    bool isEdit = editDoc != null;
    Map data = isEdit ? editDoc!.data() as Map : {};

    final productsSnap = await FirebaseFirestore.instance
        .collection("products")
        .get();
    List<String> allTags = productsSnap.docs
        .map((d) {
          final map = d.data() as Map;
          final tag = (map["tag"] ?? "").toString();
          return tag.trim();
        })
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    TextEditingController percentageC = TextEditingController(
      text: (data["percentage"] ?? "").toString(),
    );
    List<String> selectedTags = isEdit
        ? List<String>.from(data["tags"] ?? [])
        : [];
    bool selectAll = selectedTags.contains("ALL");

    DateTime? startDT = isEdit && data["start_at"] != null
        ? (data["start_at"] as Timestamp).toDate()
        : null;
    DateTime? endDT = isEdit && data["end_at"] != null
        ? (data["end_at"] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickStart() async {
              DateTime now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: startDT ?? now,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date == null) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(startDT ?? now),
              );
              if (time == null) return;
              setDialogState(
                () => startDT = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                ),
              );
            }

            Future<void> pickEnd() async {
              DateTime now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: endDT ?? now,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date == null) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(endDT ?? now),
              );
              if (time == null) return;
              setDialogState(
                () => endDT = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                ),
              );
            }

            void toggleTag(String tag) {
              setDialogState(() {
                if (tag == "ALL") {
                  selectAll = !selectAll;
                  if (selectAll) {
                    selectedTags = ["ALL"];
                  } else {
                    selectedTags = [];
                  }
                } else {
                  selectAll = false;
                  if (selectedTags.contains(tag))
                    selectedTags.remove(tag);
                  else
                    selectedTags.add(tag);
                }
              });
            }

            void saveDiscount() async {
              final pct = int.tryParse(percentageC.text.trim()) ?? 0;
              if (pct <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Enter a valid discount percentage."),
                  ),
                );
                return;
              }
              if (startDT == null || endDT == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Pick start and end date/time."),
                  ),
                );
                return;
              }
              if (!selectAll && selectedTags.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Select at least one tag or choose All."),
                  ),
                );
                return;
              }
              if (endDT!.isBefore(startDT!)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("End time must be after start time."),
                  ),
                );
                return;
              }

              try {
                final discountDoc = {
                  "percentage": pct,
                  "tags": selectAll ? ["ALL"] : selectedTags,
                  "start_at": Timestamp.fromDate(startDT!),
                  "end_at": Timestamp.fromDate(endDT!),
                  "created_at": FieldValue.serverTimestamp(),
                };

                if (isEdit) {
                  await FirebaseFirestore.instance
                      .collection("discounts")
                      .doc(editDoc!.id)
                      .update(discountDoc);
                } else {
                  await FirebaseFirestore.instance
                      .collection("discounts")
                      .add(discountDoc);
                }

                final now = DateTime.now();
                if (!(endDT!.isBefore(now))) {
                  if (selectAll) {
                    final all = await FirebaseFirestore.instance
                        .collection("products")
                        .get();
                    for (var p in all.docs) {
                      await FirebaseFirestore.instance
                          .collection("products")
                          .doc(p.id)
                          .update({"discount": pct});
                    }
                  } else {
                    for (var t in selectedTags) {
                      final snap = await FirebaseFirestore.instance
                          .collection("products")
                          .where("tag", isEqualTo: t)
                          .get();
                      for (var p in snap.docs) {
                        await FirebaseFirestore.instance
                            .collection("products")
                            .doc(p.id)
                            .update({"discount": pct});
                      }
                    }
                  }
                }

                await fetchDiscounts();
                await fetchProducts();

                Navigator.pop(context);
                await expireDiscounts();
              } catch (e) {
                print("Error saving discount: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to save discount.")),
                );
              }
            }

            return AlertDialog(
              backgroundColor: bgPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(isEdit ? "Edit Discount" : "Add Discount"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      inputBox(percentageC, "Discount (%)"),
                      const SizedBox(height: 12),
                      const Text("Tags (multi-select):"),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            label: const Text("Select All"),
                            selected: selectAll,
                            onSelected: (v) => toggleTag("ALL"),
                          ),
                          ...allTags.map((t) {
                            final selected = selectedTags.contains(t);
                            return FilterChip(
                              label: Text(t),
                              selected: selected,
                              onSelected: (_) => toggleTag(t),
                            );
                          }).toList(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: pickStart,
                            child: Text(
                              startDT == null
                                  ? "Pick Start"
                                  : "Start: ${startDT!.toString()}",
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: pickEnd,
                            child: Text(
                              endDT == null
                                  ? "Pick End"
                                  : "End: ${endDT!.toString()}",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(onPressed: saveDiscount, child: const Text("Save")),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> expireDiscounts() async {
    final now = DateTime.now();
    final expiredSnap = await FirebaseFirestore.instance
        .collection("discounts")
        .where("end_at", isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    if (expiredSnap.docs.isEmpty) return;

    for (var doc in expiredSnap.docs) {
      final data = doc.data() as Map;
      final tags = List<String>.from(data["tags"] ?? []);
      final archivedData = Map<String, dynamic>.from(data);
      archivedData["archived_at"] = FieldValue.serverTimestamp();
      archivedData["original_id"] = doc.id;
      final archivedRef = await FirebaseFirestore.instance
          .collection("archived_discounts")
          .add(archivedData);
      if (tags.contains("ALL")) {
        final all = await FirebaseFirestore.instance
            .collection("products")
            .get();
        for (var p in all.docs) {
          await FirebaseFirestore.instance
              .collection("products")
              .doc(p.id)
              .update({"discount": 0});
        }
      } else {
        for (var t in tags) {
          final snap = await FirebaseFirestore.instance
              .collection("products")
              .where("tag", isEqualTo: t)
              .get();
          for (var p in snap.docs) {
            await FirebaseFirestore.instance
                .collection("products")
                .doc(p.id)
                .update({"discount": 0});
          }
        }
      }
      await FirebaseFirestore.instance
          .collection("discounts")
          .doc(doc.id)
          .delete();
    }
    await fetchDiscounts();
    await fetchProducts();
    await fetchArchivedDiscounts();
  }

  Future<void> archiveSelected() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one item.")),
      );
      return;
    }

    if (viewMode == ViewMode.products) {
      for (var id in selectedItems) {
        final doc = await FirebaseFirestore.instance
            .collection("products")
            .doc(id)
            .get();
        if (!doc.exists) continue;
        final data = doc.data()!;
        final archivedData = Map<String, dynamic>.from(data);
        archivedData["archived_at"] = FieldValue.serverTimestamp();
        archivedData["original_id"] = id;
        final arcRef = await FirebaseFirestore.instance
            .collection("archived_products")
            .add(archivedData);
        await FirebaseFirestore.instance
            .collection("products")
            .doc(id)
            .delete();
      }
      selectedItems.clear();
      await fetchProducts();
      await fetchArchivedProducts();
    } else if (viewMode == ViewMode.discounts) {
      for (var id in selectedItems) {
        final doc = await FirebaseFirestore.instance
            .collection("discounts")
            .doc(id)
            .get();
        if (!doc.exists) continue;
        final data = doc.data()!;
        final archivedData = Map<String, dynamic>.from(data);
        archivedData["archived_at"] = FieldValue.serverTimestamp();
        archivedData["original_id"] = id;
        await FirebaseFirestore.instance
            .collection("archived_discounts")
            .add(archivedData);

        final tags = List<String>.from(data["tags"] ?? []);
        if (tags.contains("ALL")) {
          final all = await FirebaseFirestore.instance
              .collection("products")
              .get();
          for (var p in all.docs) {
            await FirebaseFirestore.instance
                .collection("products")
                .doc(p.id)
                .update({"discount": 0});
          }
        } else {
          for (var t in tags) {
            final snap = await FirebaseFirestore.instance
                .collection("products")
                .where("tag", isEqualTo: t)
                .get();
            for (var p in snap.docs) {
              await FirebaseFirestore.instance
                  .collection("products")
                  .doc(p.id)
                  .update({"discount": 0});
            }
          }
        }

        await FirebaseFirestore.instance
            .collection("discounts")
            .doc(id)
            .delete();
      }
      selectedItems.clear();
      await fetchDiscounts();
      await fetchArchivedDiscounts();
    }
  }

  void confirmDeleteOrArchive() {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one item.")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgPink,
          title: const Text("Confirm"),
          content: const Text("Are you sure?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (viewMode == ViewMode.archives) {
                  if (archiveSub == ArchiveSub.products) {
                    for (var id in selectedItems) {
                      await FirebaseFirestore.instance
                          .collection("archived_products")
                          .doc(id)
                          .delete();
                    }
                    selectedItems.clear();
                    await fetchArchivedProducts();
                  } else {
                    for (var id in selectedItems) {
                      await FirebaseFirestore.instance
                          .collection("archived_discounts")
                          .doc(id)
                          .delete();
                    }
                    selectedItems.clear();
                    await fetchArchivedDiscounts();
                  }
                } else {
                  await archiveSelected();
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> retrieveFromArchive() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one item.")),
      );
      return;
    }

    if (archiveSub == ArchiveSub.products) {
      for (var arcId in selectedItems) {
        final arcDoc = await FirebaseFirestore.instance
            .collection("archived_products")
            .doc(arcId)
            .get();
        if (!arcDoc.exists) continue;
        final data = arcDoc.data()!;
        final originalId = data["original_id"];
        final newData = Map<String, dynamic>.from(data);
        newData.remove("archived_at");
        newData.remove("original_id");
        await FirebaseFirestore.instance.collection("products").add(newData);
        await FirebaseFirestore.instance
            .collection("archived_products")
            .doc(arcId)
            .delete();
      }
      selectedItems.clear();
      await fetchProducts();
      await fetchArchivedProducts();
    } else {
      final now = DateTime.now();
      for (var arcId in selectedItems) {
        final arcDoc = await FirebaseFirestore.instance
            .collection("archived_discounts")
            .doc(arcId)
            .get();
        if (!arcDoc.exists) continue;
        final data = arcDoc.data()!;
        final newData = Map<String, dynamic>.from(data);
        newData.remove("archived_at");
        newData.remove("original_id");
        final newRef = await FirebaseFirestore.instance
            .collection("discounts")
            .add(newData);
        final tags = List<String>.from(newData["tags"] ?? []);
        final endTs = newData["end_at"] as Timestamp?;
        if (endTs != null && endTs.toDate().isAfter(now)) {
          final pct = newData["percentage"] ?? 0;
          if (tags.contains("ALL")) {
            final all = await FirebaseFirestore.instance
                .collection("products")
                .get();
            for (var p in all.docs) {
              await FirebaseFirestore.instance
                  .collection("products")
                  .doc(p.id)
                  .update({"discount": pct});
            }
          } else {
            for (var t in tags) {
              final snap = await FirebaseFirestore.instance
                  .collection("products")
                  .where("tag", isEqualTo: t)
                  .get();
              for (var p in snap.docs) {
                await FirebaseFirestore.instance
                    .collection("products")
                    .doc(p.id)
                    .update({"discount": pct});
              }
            }
          }
        }
        await FirebaseFirestore.instance
            .collection("archived_discounts")
            .doc(arcId)
            .delete();
      }
      selectedItems.clear();
      await fetchDiscounts();
      await fetchArchivedDiscounts();
    }
  }

  void handleEdit() {
    if (selectedItems.length != 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select 1 item to edit.")));
      return;
    }
    final id = selectedItems.first;
    if (viewMode == ViewMode.products) {
      final doc = productList.firstWhere((d) => d.id == id);
      showProductForm(editDoc: doc);
    } else if (viewMode == ViewMode.discounts) {
      final doc = discountList.firstWhere((d) => d.id == id);
      showDiscountForm(editDoc: doc);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot edit items in archive. Retrieve first."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(onMenuTap: () {}),
            const SizedBox(height: 10),
            const Text(
              "Products Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: inputBox(
                searchC,
                viewMode == ViewMode.products
                    ? "Search Products"
                    : viewMode == ViewMode.discounts
                    ? "Search Discounts"
                    : "Search Archives",
              ),
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionBtn("Add", () => _onAddTapped()),
                _actionBtn("Edit", handleEdit),
                _actionBtn("Delete", confirmDeleteOrArchive),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeBtn("Products", ViewMode.products),
                const SizedBox(width: 8),
                _modeBtn("Discounts", ViewMode.discounts),
                const SizedBox(width: 8),
                _modeBtn("Archives", ViewMode.archives),
              ],
            ),

            const SizedBox(height: 12),

            if (viewMode == ViewMode.archives)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _archiveBtn("Products", ArchiveSub.products),
                  const SizedBox(width: 8),
                  _archiveBtn("Discounts", ArchiveSub.discounts),
                  const SizedBox(width: 8),
                  _actionBtn("Retrieve", retrieveFromArchive),
                ],
              ),

            const SizedBox(height: 16),

            Expanded(child: _buildTableArea()),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: bottomIndex,
        onTap: (index) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            ['/home', '/offer', '/cart', '/profile'][index],
            (_) => false,
          );
        },
      ),
    );
  }

  Widget _buildTableArea() {
    if (viewMode == ViewMode.products) {
      if (filteredList.isEmpty)
        return const Center(child: Text("No products found."));
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Images")),
            DataColumn(label: Text("Title")),
            DataColumn(label: Text("Price")),
            DataColumn(label: Text("Qty")),
            DataColumn(label: Text("Category")),
            DataColumn(label: Text("Tag")),
            DataColumn(label: Text("Discount (%)")),
          ],
          rows: filteredList.map((doc) {
            String id = doc.id;
            Map data = doc.data() as Map;
            List images = data["images"] ?? [];
            return DataRow(
              selected: selectedItems.contains(id),
              onSelectChanged: (val) {
                setState(() {
                  val == true
                      ? selectedItems.add(id)
                      : selectedItems.remove(id);
                });
              },
              cells: [
                DataCell(
                  SizedBox(
                    width: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: images.map<Widget>((img) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 50,
                          height: 50,
                          child: Image.memory(
                            base64Decode(img),
                            fit: BoxFit.cover,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                DataCell(Text(data["title"] ?? "")),
                DataCell(Text(data["price"] ?? "")),
                DataCell(Text(data["quantity"] ?? "")),
                DataCell(Text((data["categories"] as List?)?.join(", ") ?? "")),
                DataCell(Text((data["tag"] ?? "").toString())),
                DataCell(Text((data["discount"] ?? 0).toString())),
              ],
            );
          }).toList(),
        ),
      );
    } else if (viewMode == ViewMode.discounts) {
      if (filteredDiscountList.isEmpty)
        return const Center(child: Text("No discounts found."));
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Tags")),
            DataColumn(label: Text("Percentage")),
            DataColumn(label: Text("Start")),
            DataColumn(label: Text("End")),
            DataColumn(label: Text("Created")),
          ],
          rows: filteredDiscountList.map((doc) {
            String id = doc.id;
            Map data = doc.data() as Map;
            final tags = (data["tags"] as List?)?.join(", ") ?? "";
            final start = data["start_at"] != null
                ? (data["start_at"] as Timestamp).toDate().toString()
                : "";
            final end = data["end_at"] != null
                ? (data["end_at"] as Timestamp).toDate().toString()
                : "";
            final created = data["created_at"] != null
                ? (data["created_at"] as Timestamp).toDate().toString()
                : "";
            return DataRow(
              selected: selectedItems.contains(id),
              onSelectChanged: (val) {
                setState(() {
                  val == true
                      ? selectedItems.add(id)
                      : selectedItems.remove(id);
                });
              },
              cells: [
                DataCell(Text(tags)),
                DataCell(Text((data["percentage"] ?? "").toString())),
                DataCell(Text(start)),
                DataCell(Text(end)),
                DataCell(Text(created)),
              ],
            );
          }).toList(),
        ),
      );
    } else {
      if (archiveSub == ArchiveSub.products) {
        if (archivedProducts.isEmpty)
          return const Center(child: Text("No archived products."));
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Title")),
              DataColumn(label: Text("Tag")),
              DataColumn(label: Text("Product ID")),
              DataColumn(label: Text("Archived At")),
            ],
            rows: archivedProducts.map((doc) {
              String id = doc.id;
              Map data = doc.data() as Map;
              final archivedAt = data["archived_at"] != null
                  ? (data["archived_at"] as Timestamp).toDate().toString()
                  : "";
              return DataRow(
                selected: selectedItems.contains(id),
                onSelectChanged: (val) {
                  setState(() {
                    val == true
                        ? selectedItems.add(id)
                        : selectedItems.remove(id);
                  });
                },
                cells: [
                  DataCell(Text(data["title"] ?? "")),
                  DataCell(Text(data["tag"] ?? "")),
                  DataCell(Text((data["product_id"] ?? "").toString())),
                  DataCell(Text(archivedAt)),
                ],
              );
            }).toList(),
          ),
        );
      } else {
        if (archivedDiscounts.isEmpty)
          return const Center(child: Text("No archived discounts."));
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Tags")),
              DataColumn(label: Text("Percentage")),
              DataColumn(label: Text("Start")),
              DataColumn(label: Text("End")),
              DataColumn(label: Text("Archived At")),
            ],
            rows: archivedDiscounts.map((doc) {
              String id = doc.id;
              Map data = doc.data() as Map;
              final archivedAt = data["archived_at"] != null
                  ? (data["archived_at"] as Timestamp).toDate().toString()
                  : "";
              final tags = (data["tags"] as List?)?.join(", ") ?? "";
              final start = data["start_at"] != null
                  ? (data["start_at"] as Timestamp).toDate().toString()
                  : "";
              final end = data["end_at"] != null
                  ? (data["end_at"] as Timestamp).toDate().toString()
                  : "";
              return DataRow(
                selected: selectedItems.contains(id),
                onSelectChanged: (val) {
                  setState(() {
                    val == true
                        ? selectedItems.add(id)
                        : selectedItems.remove(id);
                  });
                },
                cells: [
                  DataCell(Text(tags)),
                  DataCell(Text((data["percentage"] ?? "").toString())),
                  DataCell(Text(start)),
                  DataCell(Text(end)),
                  DataCell(Text(archivedAt)),
                ],
              );
            }).toList(),
          ),
        );
      }
    }
  }

  Widget _actionBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: btnPurple,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _modeBtn(String text, ViewMode mode) {
    final selected = viewMode == mode;
    return GestureDetector(
      onTap: () async {
        setState(() {
          viewMode = mode;
          selectedItems.clear();
        });
        if (mode == ViewMode.products) await fetchProducts();
        if (mode == ViewMode.discounts) await fetchDiscounts();
        if (mode == ViewMode.archives) {
          await fetchArchivedProducts();
          await fetchArchivedDiscounts();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? btnPurple : Color(0xFFF1D9FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? btnPurple : Colors.white24),
        ),
        child: Text(
          text,
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _archiveBtn(String text, ArchiveSub sub) {
    final selected = archiveSub == sub;
    return GestureDetector(
      onTap: () async {
        setState(() {
          archiveSub = sub;
          selectedItems.clear();
        });
        if (sub == ArchiveSub.products)
          await fetchArchivedProducts();
        else
          await fetchArchivedDiscounts();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? btnPurple : Color(0xFFF1D9FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? btnPurple : Colors.white24),
        ),
        child: Text(
          text,
          style: TextStyle(color: selected ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  void _onAddTapped() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgPink,
        title: const Text("Add"),
        content: const Text("Choose what to add"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showProductForm();
            },
            child: Center(child: const Text("Add Product")),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showDiscountForm();
            },
            child: Center(child: const Text("Add Discount")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void confirmDeleteOrArchiveBulk() {
    if (viewMode == ViewMode.archives) {
      confirmDelete();
    } else {
      confirmArchive();
    }
  }

  void confirmDelete() {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one item.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgPink,
          title: const Text("Delete Permanently"),
          content: const Text(
            "Are you sure? This will permanently delete selected archived items.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (archiveSub == ArchiveSub.products) {
                  for (var id in selectedItems) {
                    await FirebaseFirestore.instance
                        .collection("archived_products")
                        .doc(id)
                        .delete();
                  }
                  selectedItems.clear();
                  await fetchArchivedProducts();
                } else {
                  for (var id in selectedItems) {
                    await FirebaseFirestore.instance
                        .collection("archived_discounts")
                        .doc(id)
                        .delete();
                  }
                  selectedItems.clear();
                  await fetchArchivedDiscounts();
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void confirmArchive() {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one item.")),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgPink,
          title: const Text("Archive Items"),
          content: const Text("Move selected items to archive?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await archiveSelected();
              },
              child: const Text("Archive"),
            ),
          ],
        );
      },
    );
  }

  Widget inputBox(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: fieldPurple,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}
