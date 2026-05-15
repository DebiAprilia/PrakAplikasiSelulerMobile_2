class ItemModel {
  final int id;
  final String name;
  final String description;

  ItemModel({required this.id, required this.name, required this.description});

  //Konversi ke Map untuk disimpan ke SharedPreferences
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'description': description};
  }

  //Konversi dari map ke ItemModel
  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
    );
  }
}
