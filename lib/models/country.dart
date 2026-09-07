class Country {
  final String id;
  final String name;

  const Country({required this.id, required this.name});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
