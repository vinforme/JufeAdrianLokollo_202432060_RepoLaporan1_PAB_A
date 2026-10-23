import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radiohead Catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, 
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFA233B), 
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        fontFamily: 'Roboto', 
      ),
      home: const HomeKatalog(),
    );
  }
}

// Kriteria 2 & 3: Model data dengan minimal 3 field dan 3 tipe data berbeda (String, int, bool)
class UserProfile {
  final String name;
  final String nim;
  final int batchYear;
  final bool isActiveStudent;

  const UserProfile({
    required this.name,
    required this.nim,
    required this.batchYear,
    required this.isActiveStudent,
  });
}

class Album {
  final String collectionName;
  final String artistName;
  String artworkUrl;
  String? customDescription;

  Album({
    required this.collectionName,
    required this.artistName,
    required this.artworkUrl,
    this.customDescription,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    String imageUrl = '';
    if (json['image'] != null && (json['image'] as List).isNotEmpty) {
      imageUrl = (json['image'] as List).last['#text'] ?? '';
    }

    return Album(
      collectionName: json['name'] ?? 'Unknown Album',
      artistName: json['artist'] != null ? (json['artist']['name'] ?? 'Unknown Artist') : 'Unknown Artist',
      artworkUrl: imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          runtimeType == other.runtimeType &&
          collectionName == other.collectionName;

  @override
  int get hashCode => collectionName.hashCode;
}

class HomeKatalog extends StatefulWidget {
  const HomeKatalog({super.key});

  @override
  State<HomeKatalog> createState() => _HomeKatalogState();
}

class _HomeKatalogState extends State<HomeKatalog> {
  List<Album> catalogAlbums = [];
  List<Album> listenedAlbums = [];
  bool isLoading = false;

  final UserProfile myProfile = const UserProfile(
    name: 'Jufe Adrian Lokollo',
    nim: '202432060',
    batchYear: 2024,
    isActiveStudent: true,
  );

  @override
  void initState() {
    super.initState();
    fetchLastFmData();
  }

  Future<void> fetchLastFmData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
          'https://ws.audioscrobbler.com/2.0/?method=artist.gettopalbums&artist=radiohead&api_key=3cc634743778571752b24d55d27919d0&format=json&limit=25');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['topalbums']['album'];

        if (mounted) {
          setState(() {
            catalogAlbums = results.map((json) => Album.fromJson(json)).toList();
            catalogAlbums.removeWhere((album) => album.artworkUrl.isEmpty);

            if (listenedAlbums.isEmpty && catalogAlbums.length >= 3) {
              listenedAlbums.addAll(catalogAlbums.take(3));
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void toggleListened(Album album) {
    setState(() {
      if (listenedAlbums.contains(album)) {
        listenedAlbums.remove(album);
      } else {
        listenedAlbums.add(album);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, letterSpacing: -0.5)),
          bottom: const TabBar(
            indicatorColor: Color(0xFFFA233B),
            labelColor: Color(0xFFFA233B),
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(text: 'Albums'),
              Tab(text: 'Listened'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildAlbumGrid(catalogAlbums),
              _buildListenedTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListenedTab() {
    return Column(
      children: [
        // Kriteria 4: Penggunaan widget Card wajib
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 2,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFA233B).withOpacity(0.1),
                  radius: 24,
                  child: const Icon(Icons.person, color: Color(0xFFFA233B)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Library Owner',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${myProfile.name} - ${myProfile.nim}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: listenedAlbums.isEmpty
              ? const Center(
                  child: Text('Belum ada album yang ditambahkan',
                      style: TextStyle(color: Colors.grey, fontSize: 16)))
              : _buildAlbumGrid(listenedAlbums),
        ),
      ],
    );
  }

  Widget _buildAlbumGrid(List<Album> albums) {
    if (isLoading && albums == catalogAlbums) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFA233B)));
    }

    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 5 : 3;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.65, 
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return AlbumGridCard(
          album: album,
          isListened: listenedAlbums.contains(album),
          onToggleListened: () => toggleListened(album),
        );
      },
    );
  }
}

class AlbumGridCard extends StatefulWidget {
  final Album album;
  final bool isListened;
  final VoidCallback onToggleListened;

  const AlbumGridCard({
    super.key,
    required this.album,
    required this.isListened,
    required this.onToggleListened,
  });

  @override
  State<AlbumGridCard> createState() => _AlbumGridCardState();
}

class _AlbumGridCardState extends State<AlbumGridCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AlbumDetailSheet(album: widget.album),
        );
        setState(() {}); // Merefresh cover jika diubah dari dalam pop-up
      },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Album dengan border melengkung halus bergaya Apple Music
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                    image: DecorationImage(
                      image: NetworkImage(widget.album.artworkUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Icon Love / Favorite
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onToggleListened,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isListened ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: widget.isListened ? const Color(0xFFFA233B) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Judul Album
          Text(
            widget.album.collectionName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Nama Artis
          Text(
            widget.album.artistName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AlbumDetailSheet extends StatefulWidget {
  final Album album;
  const AlbumDetailSheet({super.key, required this.album});

  @override
  State<AlbumDetailSheet> createState() => _AlbumDetailSheetState();
}

class _AlbumDetailSheetState extends State<AlbumDetailSheet> {
  String description = '';
  List<String> tracklist = [];
  bool isLoadingData = true;
  bool isEditing = false;
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLastFmAlbumData();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> fetchLastFmAlbumData() async {
    const String apiKey = '3cc634743778571752b24d55d27919d0';
    String cleanAlbumName = widget.album.collectionName
        .replaceAll(RegExp(r' \(.*\)'), '')
        .replaceAll(RegExp(r' - .*'), '');

    final String artist = Uri.encodeComponent(widget.album.artistName);
    final String albumName = Uri.encodeComponent(cleanAlbumName);

    final Uri url = Uri.parse(
        'https://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=$apiKey&artist=$artist&album=$albumName&format=json');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            // Ambil Deskripsi
            if (widget.album.customDescription != null) {
              description = widget.album.customDescription!;
            } else if (data['album'] != null && data['album']['wiki'] != null) {
              String rawSummary =
                  data['album']['wiki']['content'] ?? data['album']['wiki']['summary'] ?? '';
              // Menghapus link <a> bawaan last.fm dengan RegEx
              rawSummary = rawSummary.replaceAll(RegExp(r'<a href=.*</a>'), '').trim();
              description = rawSummary;
            }

            // Ambil Tracklist
            if (data['album'] != null &&
                data['album']['tracks'] != null &&
                data['album']['tracks']['track'] != null) {
              var tracksRaw = data['album']['tracks']['track'];
              if (tracksRaw is List) {
                tracklist = tracksRaw.map((t) => t['name'].toString()).toList();
              } else if (tracksRaw is Map) {
                tracklist = [tracksRaw['name'].toString()];
              }
            }

            isLoadingData = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingData = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingData = false);
    }
  }

  Future<void> _openStreaming(String service) async {
    final String query = '${widget.album.collectionName} ${widget.album.artistName}';
    Uri url;
    if (service == 'spotify') {
      url = Uri.parse('https://open.spotify.com/search/${Uri.encodeComponent(query)}/albums');
    } else {
      url = Uri.parse('https://music.apple.com/us/search?term=${Uri.encodeComponent(query)}');
    }

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Tidak dapat membuka tautan $service')));
      }
    }
  }

  Widget _buildTracklist() {
    if (tracklist.isEmpty) {
      return const Text('Tracklist not available.', style: TextStyle(color: Colors.grey));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracklist.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text('${index + 1}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ),
              Expanded(
                child: Text(
                  tracklist[index],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescription() {
    if (isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _descController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Add album description...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 12),
          // Kriteria 4: Wajib memakai ElevatedButton
          ElevatedButton(
            onPressed: () {
              setState(() {
                description = _descController.text;
                widget.album.customDescription = description;
                isEditing = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFA233B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Description'),
          )
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty)
          Text(
            description,
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          )
        else
          const Text('No description available.',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _descController.text = description;
              isEditing = true;
            });
          },
          child: Text(description.isEmpty ? 'Add Manual Description' : 'Edit Description',
              style: const TextStyle(color: Color(0xFFFA233B), fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle Indicator di bagian atas
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Album Art dengan Edit Icon
                  Stack(
                    children: [
                      Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10)),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(widget.album.artworkUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                              ],
                            ),
                            child: const Icon(Icons.edit, size: 20, color: Colors.black87),
                          ),
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setState(() {
                                // Menggunakan image.path karena XFile bekerja dengan Blob URL di web
                                widget.album.artworkUrl = image.path;
                              });
                            }
                          },
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Judul dan Artis
                  Text(
                    widget.album.collectionName,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.album.artistName,
                    style: const TextStyle(
                        fontSize: 18, color: Color(0xFFFA233B), fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Tombol Where to Listen (Spotify & Apple Music) dengan efek Glowing
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1ED760), Color(0xFF128C3D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF1ED760).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openStreaming('spotify'),
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.headphones, size: 20, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Spotify',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: -0.3)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFA233B), Color(0xFFC00C20)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFFFA233B).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openStreaming('apple'),
                              borderRadius: BorderRadius.circular(16),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.apple, size: 22, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text('Apple Music',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: -0.3)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (isLoadingData)
                    const Center(child: CircularProgressIndicator(color: Color(0xFFFA233B)))
                  else ...[
                    // Area Deskripsi
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('About Album',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 12),
                    _buildDescription(),

                    const SizedBox(height: 32),

                    // Area Daftar Lagu
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Tracklist',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),
                    _buildTracklist(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}