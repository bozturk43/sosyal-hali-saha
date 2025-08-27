class City {
  final int id;
  final String name;

  City({required this.id, required this.name});

  // Gelen JSON verisinden bir City nesnesi oluşturmak için factory constructor.
  factory City.fromJson(Map<String, dynamic> json) {
    return City(id: json['id'], name: json['name']);
  }
}
