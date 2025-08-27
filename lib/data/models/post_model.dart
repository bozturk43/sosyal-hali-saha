class Post {
  final int id;
  final String? description;
  // Medya URL'sini de ekleyeceğiz
  Post({required this.id, this.description});
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(id: json['id'], description: json['attributes']['description']);
  }
}
