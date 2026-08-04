SELECT full_name, xp, coins, grade FROM users WHERE id = ?;

SELECT full_name, xp FROM users ORDER BY xp DESC LIMIT 10;

SELECT id, full_name, email, grade, has_selected_grade, xp, coins, points, challenge_streak, last_challenge_date
FROM users WHERE email = ?;

SELECT item_id FROM owned_items WHERE user_id = ?;

UPDATE users SET xp = xp + ?, coins = coins + ?, points = points + ? WHERE id = ?;