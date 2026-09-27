class VideoChannel {
  const VideoChannel({
    required this.requestChannel,
    required this.name,
    this.state = '',
    this.mainStream = '',
    this.extraStream = '',
  });

  final int requestChannel;
  final String name;
  final String state;
  final String mainStream;
  final String extraStream;
}
