-- ================================================
-- ТЕСТОВЫЕ ДАННЫЕ
-- ================================================

-- Пользователи
INSERT INTO users (username, email, full_name, role, rating, country) VALUES
('admin', 'admin@cp.com', 'System Administrator', 'admin', 0, 'Russia'),
('judge1', 'judge1@cp.com', 'Ivan Petrov', 'jury', 0, 'Russia'),
('tourist', 'tourist@cp.com', 'Gennady Korotkevich', 'participant', 3800, 'Belarus'),
('petr', 'petr@cp.com', 'Petr Mitrichev', 'participant', 3600, 'Russia'),
('scott', 'scott@cp.com', 'Scott Wu', 'participant', 3400, 'USA'),
('alice', 'alice@cp.com', 'Alice Johnson', 'participant', 2100, 'UK'),
('bob', 'bob@cp.com', 'Bob Smith', 'participant', 1900, 'Canada'),
('charlie', 'charlie@cp.com', 'Charlie Brown', 'participant', 1700, 'Germany'),
('david', 'david@cp.com', 'David Lee', 'participant', 1500, 'South Korea'),
('emma', 'emma@cp.com', 'Emma Wilson', 'participant', 1300, 'Australia');

-- Соревнования
INSERT INTO contests (title, description, contest_type, status, start_time, duration_minutes, created_by) VALUES
('Spring Algorithm Contest 2025', 'Annual spring programming competition', 'ACM_ICPC', 'finished', '2025-03-15 10:00:00', 300, 1),
('Codeforces Round #900', 'Regular Codeforces round', 'Codeforces', 'finished', '2025-11-20 18:00:00', 120, 1),
('Winter Cup 2025', 'Winter championship', 'IOI', 'running', '2025-12-20 12:00:00', 240, 1),
('Practice Contest', 'Training contest for beginners', 'Codeforces', 'upcoming', '2025-12-25 15:00:00', 180, 2);

-- Задачи
INSERT INTO problems (title, description, difficulty, time_limit_ms, memory_limit_mb, author_id) VALUES
('Two Sum', 'Given an array of integers, return indices of two numbers that add up to a target.', 'easy', 1000, 256, 2),
('Binary Search', 'Implement binary search algorithm.', 'easy', 1000, 256, 2),
('Sorting Array', 'Sort an array using any efficient algorithm.', 'easy', 2000, 512, 2),
('Longest Common Subsequence', 'Find the longest common subsequence of two strings.', 'medium', 2000, 512, 2),
('Graph Shortest Path', 'Find shortest path in weighted graph using Dijkstra.', 'medium', 3000, 512, 2),
('Dynamic Programming Problem', 'Classic DP problem with optimal substructure.', 'hard', 3000, 512, 2),
('Tree Traversal', 'Implement in-order tree traversal.', 'medium', 2000, 256, 2),
('Max Flow Min Cut', 'Solve maximum flow problem in network.', 'hard', 5000, 1024, 2);

-- Связь задач с контестами
INSERT INTO contest_problems (contest_id, problem_id, problem_order, max_score) VALUES
(1, 1, 1, 100), (1, 2, 2, 100), (1, 3, 3, 100), (1, 4, 4, 100),
(2, 4, 1, 100), (2, 5, 2, 150), (2, 6, 3, 200),
(3, 5, 1, 100), (3, 6, 2, 150), (3, 7, 3, 100), (3, 8, 4, 200);

-- Теги
INSERT INTO tags (tag_name, description) VALUES
('arrays', 'Array manipulation problems'),
('binary-search', 'Binary search algorithm'),
('sorting', 'Sorting algorithms'),
('dynamic-programming', 'Dynamic programming techniques'),
('graphs', 'Graph theory problems'),
('trees', 'Tree data structures'),
('greedy', 'Greedy algorithms'),
('math', 'Mathematical problems');

-- Связь задач с тегами
INSERT INTO problem_tags (problem_id, tag_id) VALUES
(1, 1), (1, 7),
(2, 2),
(3, 3), (3, 1),
(4, 4),
(5, 5), (5, 7),
(6, 4),
(7, 6),
(8, 5), (8, 7);

-- Тестовые данные для задач
INSERT INTO testcases (problem_id, input_data, expected_output, is_sample, test_order) VALUES
(1, '[2,7,11,15]\n9', '0 1', TRUE, 1),
(1, '[3,2,4]\n6', '1 2', FALSE, 2),
(2, '5\n1 2 3 4 5\n3', '2', TRUE, 1),
(2, '10\n1 3 5 7 9 11 13 15 17 19\n11', '5', FALSE, 2),
(3, '5\n5 2 8 1 9', '1 2 5 8 9', TRUE, 1),
(4, 'ABCDGH\nAEDFHR', '3', TRUE, 1),
(5, '5 6\n0 1 4\n0 2 2\n1 2 1\n1 3 5\n2 3 8\n3 4 3\n0 4', '9', TRUE, 1);

-- Посылки решений (Contest 1 - завершен)
INSERT INTO submissions (contest_id, problem_id, user_id, source_code, language, verdict, execution_time_ms, memory_used_mb, score, submitted_at) VALUES
-- tourist решает все задачи
(1, 1, 3, 'def two_sum(nums, target):\n    return [0, 1]', 'Python', 'accepted', 45, 12.5, 100, '2025-03-15 10:15:00'),
(1, 2, 3, 'def binary_search(arr, x):\n    return 0', 'Python', 'accepted', 38, 11.2, 100, '2025-03-15 10:30:00'),
(1, 3, 3, 'def sort_array(arr):\n    return sorted(arr)', 'Python', 'accepted', 120, 15.8, 100, '2025-03-15 10:45:00'),
(1, 4, 3, 'def lcs(s1, s2):\n    return 0', 'Python', 'accepted', 250, 18.5, 100, '2025-03-15 11:00:00'),

-- petr решает 3 задачи
(1, 1, 4, '#include<iostream>\nint main(){return 0;}', 'C++', 'accepted', 35, 8.2, 100, '2025-03-15 10:20:00'),
(1, 2, 4, '#include<algorithm>', 'C++', 'accepted', 30, 7.8, 100, '2025-03-15 10:35:00'),
(1, 3, 4, 'vector<int> sort()', 'C++', 'accepted', 95, 10.5, 100, '2025-03-15 10:50:00'),
(1, 4, 4, 'int lcs()', 'C++', 'wrong_answer', 180, 12.0, 0, '2025-03-15 11:10:00'),

-- scott решает 2 задачи
(1, 1, 5, 'public class Solution {}', 'Java', 'accepted', 55, 25.3, 100, '2025-03-15 10:25:00'),
(1, 2, 5, 'public int binarySearch(){}', 'Java', 'accepted', 48, 23.1, 100, '2025-03-15 10:40:00'),
(1, 3, 5, 'public void sort(){}', 'Java', 'time_limit', 2100, 30.0, 0, '2025-03-15 11:05:00'),

-- alice решает 2 задачи
(1, 1, 6, 'def solve(): pass', 'Python', 'accepted', 50, 13.0, 100, '2025-03-15 10:30:00'),
(1, 2, 6, 'def bs(): pass', 'Python', 'accepted', 42, 12.5, 100, '2025-03-15 10:50:00'),

-- Посылки для Contest 2 (завершен)
(2, 4, 3, 'dp solution', 'C++', 'accepted', 280, 20.5, 100, '2025-11-20 18:25:00'),
(2, 5, 3, 'dijkstra', 'C++', 'accepted', 450, 35.2, 150, '2025-11-20 18:50:00'),
(2, 6, 3, 'dp hard', 'C++', 'accepted', 890, 48.5, 200, '2025-11-20 19:20:00'),

(2, 4, 4, 'dp attempt', 'C++', 'accepted', 310, 22.1, 100, '2025-11-20 18:30:00'),
(2, 5, 4, 'shortest path', 'C++', 'accepted', 520, 38.0, 150, '2025-11-20 19:00:00'),
(2, 6, 4, 'hard problem', 'C++', 'wrong_answer', 950, 50.0, 0, '2025-11-20 19:35:00'),

-- Посылки для Contest 3 (идет сейчас)
(3, 5, 6, 'graph solution', 'Python', 'accepted', 580, 40.5, 100, '2025-12-20 12:30:00'),
(3, 7, 6, 'tree traversal', 'Python', 'accepted', 220, 18.5, 100, '2025-12-20 13:00:00');

-- Обновляем статус контестов
UPDATE contests SET status = 'finished' WHERE contest_id IN (1, 2);
UPDATE contests SET status = 'running' WHERE contest_id = 3;
