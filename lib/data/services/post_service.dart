import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:sosyal_halisaha/core/constants/api_constants.dart';
import 'package:sosyal_halisaha/data/models/post_model.dart';
import 'package:sosyal_halisaha/data/services/dio_provider.dart';

// Bir provider'a dışarıdan parametre vermek için .family kullanırız.
// Burada, hangi kullanıcının gönderilerini istediğimizi belirtmek için userId alıyoruz.
final userPostsProvider = FutureProvider.family<List<Post>, int>((ref, userId) {
  final postService = ref.watch(postServiceProvider);
  return postService.getPostsByUser(userId);
});

final postServiceProvider = Provider(
  (ref) => PostService(ref.watch(dioProvider)),
);

class PostService {
  final Dio _dio;
  PostService(this._dio);

  Future<List<Post>> getPostsByUser(int userId) async {
    try {
      // Strapi'de bir kullanıcının gönderilerini filtreleyerek çekme
      final response = await _dio.get(
        '/api/posts?filters[author][id][\$eq]=$userId&populate=media',
      );
      final List<dynamic> data = response.data['data'];
      return data.map((postJson) => Post.fromJson(postJson)).toList();
    } catch (e) {
      throw Exception('Gönderiler alınamadı.');
    }
  }
}
