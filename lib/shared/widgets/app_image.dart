import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Image fields hold either a bundled asset path (`assets/...`) or a remote
/// URL (fighter photoUrl, scraped event art). Resolve either one.
ImageProvider appImageProvider(String src) => src.startsWith('http')
    ? CachedNetworkImageProvider(src)
    : AssetImage(src) as ImageProvider;
