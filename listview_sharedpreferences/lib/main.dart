import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:listview_sharedpreferences/item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi List Item',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: ItemListPage(),
    );
  }
}

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<ItemModel> _items = [];
  List<ItemModel> _filteredItems = []; //menyimpan hasil filter
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchController =
      TextEditingController(); //Untuk hasil pencarian

  //Variabel untuk edit
  ItemModel? _editingItem;

  //Data dummy awal
  final List<ItemModel> _dummyItems = [
    ItemModel(id: 1, name: 'Laptop', description: 'Laptop Gaming'),
    ItemModel(id: 2, name: 'Mouse', description: 'Mouse Wireless'),
    ItemModel(id: 3, name: 'Keyboard', description: 'Keyboard Mechanical'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  //Filter item berdasarkan pencarian
  void _filterItems() {
    String query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_items);
      } else {
        _filteredItems = _items.where((item) {
          bool matchName = item.name.toLowerCase().contains(query);
          bool matchDesc = item.description.toLowerCase().contains(query);
          return matchName || matchDesc;
        }).toList();
      }
    });
  }

  //Load data dari SharedPreferences
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? itemsString = prefs.getString('item_list');

    if (itemsString != null) {
      List<dynamic> itemsMap = json.decode(itemsString);
      setState(() {
        _items = itemsMap.map((item) => ItemModel.fromMap(item)).toList();
        _filteredItems = List.from(_items);
      });
    } else {
      //jika belum ada data, gunakan data dummy
      setState(() {
        _items = List.from(_dummyItems);
        _filteredItems = List.from(_dummyItems); //tambahkan untuk pencarian
      });
      await _saveData(); //simpan data dummy ke SharedPreferences
    }
  }

  //Simpan data ke SharedPreferences
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> itemsMap = _items
        .map((item) => item.toMap())
        .toList();
    String itemsString = json.encode(itemsMap);
    await prefs.setString('item_list', itemsString);
  }

  //Tambah item baru
  Future<void> _addItem() async {
    if (_nameController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama dan deskripsi tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int newId = _items.isNotEmpty ? _items.last.id + 1 : 1;
    ItemModel newItem = ItemModel(
      id: newId,
      name: _nameController.text,
      description: _descController.text,
    );

    setState(() {
      _items.add(newItem);
      _filterItems(); //tambahkan untuk pencarian
    });

    await _saveData();
    _nameController.clear();
    _descController.clear();

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item berhasil ditambahkan'),
        backgroundColor: Colors.green, //+
      ),
    );
  }

  //+Update item yang sudah ada
  Future<void> _updateItem() async {
    if (_nameController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nama dan deskripsi tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_editingItem != null) {
      final updatedItem = ItemModel(
        id: _editingItem!.id,
        name: _nameController.text,
        description: _descController.text,
      );

      setState(() {
        int index = _items.indexWhere((item) => item.id == _editingItem!.id);
        if (index != -1) {
          _items[index] = updatedItem;
          _filterItems();
        }
      });

      await _saveData();
      _nameController.clear();
      _descController.clear();
      _editingItem = null;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item berhasil diperbarui'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  //Konfirmasi sebelum menghapus
  Future<void> _confirmDelete(ItemModel item) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Item'),
          content: Text(
            'Apakah Anda yakin ingin menghapus item "${item.name}"?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog konfirmasi
                _deleteItem(item.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  //Hapus item
  Future<void> _deleteItem(int id) async {
    setState(() {
      _items.removeWhere((item) => item.id == id);
      _filterItems();
    });
    await _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item berhasil dihapus'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  //Show dialog untuk tambah/edit ubah semua
  void _showItemDialog({ItemModel? item}) {
    _editingItem = item;

    if (item != null) {
      // Mode Edit: isi field dengan data yang ada
      _nameController.text = item.name;
      _descController.text = item.description;
    } else {
      // Mode Tambah: kosongkan field
      _nameController.clear();
      _descController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? 'Tambah Item Baru' : 'Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Item',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _nameController.clear();
                _descController.clear();
                _editingItem = null;
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: item == null ? _addItem : _updateItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: item == null ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(item == null ? 'Simpan' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daftar Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari item berdasarkan nama atau deskripsi...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterItems();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                _filterItems();
              },
            ),
          ),
        ),
      ),
      body: _filteredItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchController.text.isNotEmpty
                        ? Icons.search_off
                        : Icons.inbox,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _searchController.text.isNotEmpty
                        ? 'Tidak ada item yang sesuai'
                        : 'Tidak ada data. Tambahkan item baru',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchController.text.isNotEmpty) ...[
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        _filterItems();
                      },
                      icon: Icon(Icons.clear),
                      label: Text('Hapus Pencarian'),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${item.id}'),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        item.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showItemDialog(item: item),
                          tooltip: 'Edit Item',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(item),
                          tooltip: 'Hapus Item',
                        ),
                      ],
                    ),
                    isThreeLine: false,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        icon: Icon(Icons.add),
        label: Text('Tambah Item'),
        tooltip: 'Tambah Item Baru',
      ),
    );
  }
}
