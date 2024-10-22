import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(
      game:
          SpaceShooterGame())); // Memulai aplikasi Flutter dan menjalankan game SpaceShooterGame
}

// Game utama yang mengatur semua elemen game, termasuk pemain, musuh, dan parallax
class SpaceShooterGame extends FlameGame
    with PanDetector, HasCollisionDetection {
  late Player player;

  // Fungsi yang dijalankan saat game dimuat, digunakan untuk memuat elemen game seperti background parallax dan pemain
  @override
  Future<void> onLoad() async {
    // Memuat background parallax untuk memberikan efek gerakan bintang-bintang di latar belakang
    final parallax = await loadParallaxComponent(
      [
        ParallaxImageData('stars_0.png'),
        ParallaxImageData('stars_1.png'),
        ParallaxImageData('stars_2.png'),
      ],
      baseVelocity: Vector2(0, -5),
      repeat: ImageRepeat.repeat,
      velocityMultiplierDelta: Vector2(0, 5),
    );
    add(parallax);

    // Menambahkan pemain ke dalam game
    player = Player();
    add(player);

    // Menambahkan komponen spawn musuh secara berkala
    add(
      SpawnComponent(
        factory: (index) {
          return Enemy();
        },
        period: 1, // Musuh muncul setiap 1 detik
        area: Rectangle.fromLTWH(0, 0, size.x, -Enemy.enemySize),
      ),
    );
  }

  // Menggerakkan pemain saat pengguna menyeret layar
  @override
  void onPanUpdate(DragUpdateInfo info) {
    player.move(info.delta.global);
  }

  // Memulai tembakan saat pengguna memulai seret layar
  @override
  void onPanStart(DragStartInfo info) {
    player.startShooting();
  }

  // Menghentikan tembakan saat pengguna menghentikan seret layar
  @override
  void onPanEnd(DragEndInfo info) {
    player.stopShooting();
  }
}

// Komponen yang merepresentasikan pemain
class Player extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame> {
  Player()
      : super(
          size: Vector2(100, 150), // Ukuran pemain
          anchor: Anchor.center, // Titik jangkar di tengah sprite
        );

  late final SpawnComponent _bulletSpawner; // Komponen untuk men-spawn peluru

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Memuat animasi sprite untuk pemain
    animation = await game.loadSpriteAnimation(
      'player.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.2,
        textureSize: Vector2(32, 48),
      ),
    );

    // Menempatkan pemain di tengah layar
    position = game.size / 2;

    // Mengatur spawner untuk menembakkan peluru dari posisi pemain
    _bulletSpawner = SpawnComponent(
      period: 0.2, // Peluru ditembakkan setiap 0.2 detik
      selfPositioning: true,
      factory: (index) {
        return Bullet(
          position: position +
              Vector2(
                0,
                -height / 2,
              ),
        );
      },
      autoStart: false, // Spawner tidak dimulai otomatis
    );

    game.add(_bulletSpawner); // Menambahkan spawner peluru ke dalam game
  }

  // Fungsi untuk menggerakkan pemain berdasarkan input pengguna
  void move(Vector2 delta) {
    position.add(delta);
  }

  // Memulai penembakan peluru
  void startShooting() {
    _bulletSpawner.timer.start();
  }

  // Menghentikan penembakan peluru
  void stopShooting() {
    _bulletSpawner.timer.stop();
  }
}

// Komponen yang merepresentasikan peluru yang ditembakkan oleh pemain
class Bullet extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame> {
  Bullet({
    super.position,
  }) : super(
          size: Vector2(25, 50), // Ukuran peluru
          anchor: Anchor.center, // Titik jangkar di tengah peluru
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Memuat animasi sprite untuk peluru
    animation = await game.loadSpriteAnimation(
      'bullet.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.2,
        textureSize: Vector2(8, 16),
      ),
    );

    // Menambahkan hitbox untuk deteksi tumbukan
    add(
      RectangleHitbox(
        collisionType: CollisionType.passive,
      ),
    );
  }

  // Mengupdate posisi peluru setiap frame
  @override
  void update(double dt) {
    super.update(dt);

    position.y += dt * -500; // Peluru bergerak ke atas

    // Jika peluru keluar dari layar, hapus peluru dari game
    if (position.y < -height) {
      removeFromParent();
    }
  }
}

// Komponen yang merepresentasikan musuh dalam game
class Enemy extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame>, CollisionCallbacks {
  Enemy({
    super.position,
  }) : super(
          size: Vector2.all(enemySize), // Ukuran musuh
          anchor: Anchor.center, // Titik jangkar di tengah musuh
        );

  static const enemySize = 50.0; // Ukuran standar musuh

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Memuat animasi sprite untuk musuh
    animation = await game.loadSpriteAnimation(
      'enemy.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.2,
        textureSize: Vector2.all(16),
      ),
    );

    add(RectangleHitbox()); // Menambahkan hitbox untuk deteksi tumbukan
  }

  // Mengupdate posisi musuh setiap frame
  @override
  void update(double dt) {
    super.update(dt);

    position.y += dt * 250; // Musuh bergerak ke bawah

    // Jika musuh keluar dari layar, hapus musuh dari game
    if (position.y > game.size.y) {
      removeFromParent();
    }
  }

  // Menangani tumbukan antara musuh dan peluru
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Bullet) {
      // Hapus musuh dan peluru saat terjadi tumbukan
      removeFromParent();
      other.removeFromParent();
      game.add(Explosion(position: position)); // Tambahkan efek ledakan
    }
  }
}

// Komponen yang merepresentasikan ledakan saat musuh tertembak
class Explosion extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame> {
  Explosion({
    super.position,
  }) : super(
          size: Vector2.all(150), // Ukuran ledakan
          anchor: Anchor.center, // Titik jangkar di tengah ledakan
          removeOnFinish: true, // Hapus ledakan setelah animasi selesai
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Memuat animasi sprite untuk ledakan
    animation = await game.loadSpriteAnimation(
      'explosion.png',
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: Vector2.all(32),
        loop: false, // Animasi tidak diulang
      ),
    );
  }
}
