class ComoItem {
  final int id;
  final int itemNumber;
  final String name;
  final String description;
  final String category;
  final String keywords;

  ComoItem({
    required this.id,
    required this.itemNumber,
    required this.name,
    required this.description,
    required this.category,
    required this.keywords,
  });

  factory ComoItem.fromJson(Map<String, dynamic> json) {
    return ComoItem(
      id: json['id'],
      itemNumber: json['itemNumber'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      keywords: json['keywords'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemNumber': itemNumber,
      'name': name,
      'description': description,
      'category': category,
      'keywords': keywords,
    };
  }

  @override
  String toString() => 'ComoItem($itemNumber - $name)';
}
