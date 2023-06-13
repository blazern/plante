import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UriImagePlante extends StatelessWidget {
  final Uri uri;
  final Map<String, String>? httpHeaders;
  final dynamic Function(ImageProvider image)? imageProviderCallback;

  const UriImagePlante(this.uri,
      {Key? key, this.imageProviderCallback, this.httpHeaders})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Image result;
    if (uri.isScheme('FILE')) {
      result = Image.file(File.fromUri(uri), fit: BoxFit.cover);
    } else {
      final ImageProvider imageProvider;
      if (!kIsWeb) {
        imageProvider =
            CachedNetworkImageProvider(uri.toString(), headers: httpHeaders);
      } else {
        imageProvider = NetworkImage(uri.toString(), headers: httpHeaders);
      }
      result = Image(
          image: imageProvider,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return const Center(child: CircularProgressIndicator());
          });
    }
    imageProviderCallback?.call(result.image);
    return result;
  }
}
