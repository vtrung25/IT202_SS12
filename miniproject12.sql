-- BÀI 1) QUẢN LÝ NGƯỜI DÙNG
-- Tạo bảng Users + thêm user + xem danh sách
-- (BÀI 1.1) Tạo bảng Users
CREATE DATABASE miniProject12;
USE miniProject12;
DROP TABLE IF EXISTS Users;

CREATE TABLE Users (
  user_id INT PRIMARY KEY AUTO_INCREMENT,      -- khóa chính + tự tăng
  username VARCHAR(50) NOT NULL UNIQUE,        -- tên đăng nhập: duy nhất
  password VARCHAR(255) NOT NULL,              -- mật khẩu
  email VARCHAR(100) NOT NULL UNIQUE,          -- email: duy nhất
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP -- ngày tạo
);

-- (BÀI 1.2) Thêm dữ liệu demo Users
INSERT INTO Users (username, password, email) VALUES
('an',   'hash_an',   'an@gmail.com'),
('binh', 'hash_binh', 'binh@gmail.com'),
('cuong','hash_cuong','cuong@gmail.com'),
('dung', 'hash_dung', 'dung@gmail.com'),
('em',   'hash_em',   'em@gmail.com');

-- (BÀI 1.3) Hiển thị danh sách Users
SELECT * FROM Users;
-- Tạo các bảng
-- Posts / Comments / Friends / Likes
-- (NỀN 1) Tạo bảng Posts
DROP TABLE IF EXISTS Posts;

CREATE TABLE Posts (
  post_id INT PRIMARY KEY AUTO_INCREMENT,       -- khóa chính
  user_id INT,                                  -- người đăng
  content TEXT NOT NULL,                         -- nội dung
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP, -- thời gian đăng
  FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- (NỀN 2) Tạo bảng Comments
DROP TABLE IF EXISTS Comments;

CREATE TABLE Comments (
  comment_id INT PRIMARY KEY AUTO_INCREMENT,    -- khóa chính
  post_id INT,                                  -- bài viết
  user_id INT,                                  -- người bình luận
  content TEXT NOT NULL,                         -- nội dung
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP, -- thời gian
  FOREIGN KEY (post_id) REFERENCES Posts(post_id),
  FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- (NỀN 3) Tạo bảng Friends
DROP TABLE IF EXISTS Friends;

CREATE TABLE Friends (
  user_id INT,           -- người gửi
  friend_id INT,         -- người nhận
  status VARCHAR(20),    -- pending / accepted
  CHECK (status IN ('pending','accepted')),
  FOREIGN KEY (user_id) REFERENCES Users(user_id),
  FOREIGN KEY (friend_id) REFERENCES Users(user_id)
);

-- (NỀN 4) Tạo bảng Likes
DROP TABLE IF EXISTS Likes;

CREATE TABLE Likes (
  user_id INT,   -- người thích
  post_id INT,   -- bài viết
  FOREIGN KEY (user_id) REFERENCES Users(user_id),
  FOREIGN KEY (post_id) REFERENCES Posts(post_id)
);

-- BÀI 2) VIEW: THÔNG TIN CÔNG KHAI
-- vw_public_users: chỉ user_id, username, created_at

-- (BÀI 2.1) Tạo view công khai
DROP VIEW IF EXISTS vw_public_users;

CREATE VIEW vw_public_users AS
SELECT user_id, username, created_at
FROM Users;

-- (BÀI 2.2) SELECT từ View
SELECT * FROM vw_public_users;

-- (BÀI 2.3) So sánh với SELECT trực tiếp từ Users
SELECT * FROM Users;

-- Ghi chú: View giúp ẩn password/email -> đỡ lộ dữ liệu nhạy cảm

-- BÀI 3) INDEX: TỐI ƯU TÌM USER THEO USERNAME

-- (BÀI 3.1) Tạo index cho username
CREATE INDEX idx_users_username ON Users(username);

-- (BÀI 3.2) Truy vấn tìm user theo username
SELECT * FROM Users
WHERE username = 'an';
-- Ghi chú: có index -> tìm nhanh hơn, không phải quét cả bảng

-- Bài 4. Stored Procedure đăng bài viết sp_create_post
DELIMITER $$

CREATE PROCEDURE sp_create_post(
  IN p_user_id INT,
  IN p_content TEXT
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM Users WHERE user_id = p_user_id) THEN
    SELECT 'User không tồn tại - không thể đăng bài' AS message;
  ELSE
    INSERT INTO Posts(user_id, content) VALUES (p_user_id, p_content);
    SELECT 'Đăng bài thành công' AS message;
  END IF;
END$$

DELIMITER ;


-- Gọi procedure
CALL sp_create_post(1, 'Bài viết đầu tiên của An');
CALL sp_create_post(2, 'Xin chào, đây là bài viết của Bình');

-- Bài 5. VIEW News Feed 7 ngày gần nhất vw_recent_posts
CREATE OR REPLACE VIEW vw_recent_posts AS
SELECT
  p.post_id,
  p.user_id,
  u.username,
  p.content,
  p.created_at
FROM Posts p
JOIN Users u ON u.user_id = p.user_id
WHERE p.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Hiển thị bài viết mới nhất
SELECT *
FROM vw_recent_posts
ORDER BY created_at DESC;

-- Bài 6
CREATE INDEX idx_posts_user_id ON Posts(user_id);
CREATE INDEX idx_posts_user_time ON Posts(user_id, created_at);

SELECT post_id, content, created_at 
FROM Posts 
WHERE user_id = 1 
ORDER BY created_at DESC;

/* PHÂN TÍCH COMPOSITE INDEX (user_id, created_at):
   - Cấu trúc: Index lưu dữ liệu đã sắp xếp sẵn: Tìm user_id xong là có ngay thứ tự created_at.
   - Hiệu quả: DB bỏ qua được bước "Filesort" (sắp xếp lại) vốn rất nặng.
   -> Kết quả: Truy vấn nhanh hơn nhiều so với chỉ dùng Index đơn lẻ. */

-- Bài 7 Thống kê hoạt động bằng Stored Procedure
delimiter //
create procedure sp_count_posts(
    in p_user_id int,
    out p_total int
)
begin
    select count(*) into p_total
    from posts
    where user_id = p_user_id;
end//
delimiter ;

-- Gọi Procedure để kiểm tra
set @total = 0;
call sp_count_posts(1, @total);
select @total;

-- Bài 8 Kiểm soát dữ liệu bằng View WITH CHECK OPTION
create view vw_active_users as
select user_id, username, created_at
from users
where user_id in (select distinct user_id from posts)
with check option;


-- BÀI 9) PROCEDURE: GỬI LỜI MỜI KẾT BẠN
-- sp_add_friend(IN p_user_id, IN p_friend_id)
-- Không cho kết bạn với chính mình


DROP PROCEDURE IF EXISTS sp_add_friend;
DELIMITER $$

CREATE PROCEDURE sp_add_friend(
  IN p_user_id INT,
  IN p_friend_id INT
)
BEGIN
  IF p_user_id = p_friend_id THEN
    SELECT 'Không được kết bạn với chính mình' AS message;
  ELSE
    INSERT INTO Friends(user_id, friend_id, status)
    VALUES (p_user_id, p_friend_id, 'pending');
    SELECT 'Đã gửi lời mời kết bạn' AS message;
  END IF;
END$$

DELIMITER ;

CALL sp_add_friend(1, 2);
CALL sp_add_friend(1, 1);
SELECT * FROM Friends;



-- BÀI 10) PROCEDURE: GỢI Ý BẠN BÈ (INOUT p_limit)
-- Gợi ý đơn giản: lấy user khác mình, giới hạn p_limit
-- (dùng IF/WHILE đúng yêu cầu, bản newbie-friendly)


DROP PROCEDURE IF EXISTS sp_suggest_friends;
DELIMITER $$

CREATE PROCEDURE sp_suggest_friends(
  IN p_user_id INT,
  INOUT p_limit INT
)
BEGIN
  DECLARE v_count INT DEFAULT 0;

  -- Nếu limit <= 0 thì set mặc định 5
  IF p_limit IS NULL OR p_limit <= 0 THEN
    SET p_limit = 5;
  END IF;

  -- Trả danh sách gợi ý (đơn giản)
  -- (WHILE ở đây để “đúng yêu cầu môn”, dù thực tế SELECT LIMIT là đủ)
  WHILE v_count < 1 DO
    SELECT user_id, username
    FROM Users
    WHERE user_id <> p_user_id
    LIMIT p_limit;
    SET v_count = 1;
  END WHILE;
END$$

DELIMITER ;

SET @lim = 3;
CALL sp_suggest_friends(1, @lim);



-- BÀI 11) TOP 5 BÀI VIẾT NHIỀU LIKE NHẤT + VIEW + INDEX Likes.post_id


-- (BÀI 11.1) Index cho Likes.post_id
CREATE INDEX idx_likes_post_id ON Likes(post_id);

-- (BÀI 11.2) Thêm likes demo
INSERT INTO Likes(user_id, post_id) VALUES
(1,1),(2,1),(3,1),
(2,2),(3,2);

-- (BÀI 11.3) Query top 5
SELECT
  p.post_id,
  p.content,
  COUNT(l.post_id) AS like_count
FROM Posts p
LEFT JOIN Likes l ON p.post_id = l.post_id
GROUP BY p.post_id, p.content
ORDER BY like_count DESC
LIMIT 5;

-- (BÀI 11.4) Tạo view vw_top_posts
DROP VIEW IF EXISTS vw_top_posts;

CREATE VIEW vw_top_posts AS
SELECT
  p.post_id,
  p.content,
  COUNT(l.post_id) AS like_count
FROM Posts p
LEFT JOIN Likes l ON p.post_id = l.post_id
GROUP BY p.post_id, p.content
ORDER BY like_count DESC
LIMIT 5;

SELECT * FROM vw_top_posts;



-- BÀI 12) QUẢN LÝ BÌNH LUẬN
-- Procedure sp_add_comment + View vw_post_comments


DROP PROCEDURE IF EXISTS sp_add_comment;
DELIMITER $$

CREATE PROCEDURE sp_add_comment(
  IN p_user_id INT,
  IN p_post_id INT,
  IN p_content TEXT
)
BEGIN
  -- Check user tồn tại
  IF (SELECT COUNT(*) FROM Users WHERE user_id = p_user_id) = 0 THEN
    SELECT 'User không tồn tại' AS message;

  -- Check post tồn tại
  ELSEIF (SELECT COUNT(*) FROM Posts WHERE post_id = p_post_id) = 0 THEN
    SELECT 'Post không tồn tại' AS message;

  ELSE
    INSERT INTO Comments(user_id, post_id, content)
    VALUES (p_user_id, p_post_id, p_content);
    SELECT 'Bình luận thành công' AS message;
  END IF;
END$$

DELIMITER ;

CALL sp_add_comment(2, 1, 'Hay đó bro!');
CALL sp_add_comment(99, 1, 'User không tồn tại');
CALL sp_add_comment(2, 99, 'Post không tồn tại');

-- View hiển thị bình luận kèm tên user
DROP VIEW IF EXISTS vw_post_comments;

CREATE VIEW vw_post_comments AS
SELECT
  c.comment_id,
  c.post_id,
  u.username,
  c.content,
  c.created_at
FROM Comments c
JOIN Users u ON c.user_id = u.user_id
ORDER BY c.created_at DESC;

SELECT * FROM vw_post_comments;

-- BÀI 13) QUẢN LÝ LƯỢT THÍCH
DROP PROCEDURE IF EXISTS sp_like_post;
DELIMITER $$

CREATE PROCEDURE sp_like_post(
  IN p_user_id INT,
  IN p_post_id INT
)
BEGIN
  -- Check đã like chưa
  IF (SELECT COUNT(*) FROM Likes WHERE user_id = p_user_id AND post_id = p_post_id) > 0 THEN
    SELECT 'Bạn đã like bài này rồi' AS message;
  ELSE
    INSERT INTO Likes(user_id, post_id) VALUES (p_user_id, p_post_id);
    SELECT 'Like thành công' AS message;
  END IF;
END$$

DELIMITER ;

CALL sp_like_post(4, 1);
CALL sp_like_post(4, 1);

-- View thống kê số like theo post
DROP VIEW IF EXISTS vw_post_likes;

CREATE VIEW vw_post_likes AS
SELECT
  post_id,
  COUNT(*) AS like_count
FROM Likes
GROUP BY post_id;

SELECT * FROM vw_post_likes;



-- BÀI 14) SEARCH USER / POST
-- sp_search_social(p_option, p_keyword)
-- option=1: search username
-- option=2: search post content


DROP PROCEDURE IF EXISTS sp_search_social;
DELIMITER $$

CREATE PROCEDURE sp_search_social(
  IN p_option INT,
  IN p_keyword VARCHAR(100)
)
BEGIN
  IF p_option = 1 THEN
    SELECT user_id, username, created_at
    FROM Users
    WHERE username LIKE CONCAT('%', p_keyword, '%');

  ELSEIF p_option = 2 THEN
    SELECT post_id, user_id, content, created_at
    FROM Posts
    WHERE content LIKE CONCAT('%', p_keyword, '%');

  ELSE
    SELECT 'Option không hợp lệ (1=user, 2=post)' AS message;
  END IF;
END$$

DELIMITER ;

-- CALL: tìm user có username chứa "an"
CALL sp_search_social(1, 'an');

-- CALL: tìm post có content chứa "database"
CALL sp_search_social(2, 'database');