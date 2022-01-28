DROP procedure IF EXISTS `test_martingale_profit_iqoption`;

DELIMITER $$
CREATE PROCEDURE `test_martingale_profit_iqoption`(p_pair VARCHAR(44), p_start DATETIME, p_end DATETIME, p_start_martingale INT, p_1_op_value DECIMAL(10,2), p_2_op_value DECIMAL(10,2), p_3_op_value DECIMAL(10,2), p_4_op_value DECIMAL(10,2), p_5_op_value DECIMAL(10,2), p_6_op_value DECIMAL(10,2))
BEGIN
	DECLARE v_id, v_rep_pattern, start_martingale, payout, previous_rep_pattern, count INT;
    DECLARE profit, first_op_value, op_profit, op_bet, capital decimal(10,2);
    DECLARE v_op_date, previous_op_date DATETIME;
    DECLARE v_pair VARCHAR(44);
	DECLARE done INT DEFAULT FALSE;  
 
	DECLARE cur1 CURSOR FOR 
		SELECT id, rep_pattern, time, pair from forex WHERE (p_pair LIKE '' OR pair LIKE p_pair) and time >= p_start and time < p_end  
			AND CASE 
				WHEN DAYOFWEEK(time) = 1 THEN HOUR(time) >= 22 
				WHEN DAYOFWEEK(time) = 2 THEN HOUR(time) < 18 OR HOUR(time) >= 22 
				WHEN DAYOFWEEK(time) = 3 THEN HOUR(time) < 18 OR HOUR(time) >= 22 
				WHEN DAYOFWEEK(time) = 4 THEN HOUR(time) < 18 OR HOUR(time) >= 22 
				WHEN DAYOFWEEK(time) = 5 THEN HOUR(time) < 18 OR HOUR(time) >= 22 
				WHEN DAYOFWEEK(time) = 6 THEN HOUR(time) < 16 OR (HOUR(time) = 16 AND MINUTE(time) < 30)   		
			END
		AND DAYOFWEEK(time) != 7
		ORDER BY id; 

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;  

	DROP TEMPORARY TABLE IF EXISTS performance;
	CREATE TEMPORARY TABLE performance (Pair VARCHAR(44), Date DATETIME, Profit DECIMAL(10,2)); 

    SET payout = 85;

	SET profit = 0;
    SET op_profit = 0;
    SET op_bet = first_op_value;
    SET capital = 41;
    
	SET previous_rep_pattern = -1;

	open cur1;    

	read_loop: loop
		fetch cur1 into v_id, v_rep_pattern, v_op_date, v_pair;	
		IF done THEN
			LEAVE read_loop;
		END IF;
        
		SET op_profit = 0;

		IF previous_rep_pattern != -1 THEN
			IF (TIMESTAMPDIFF(MINUTE,previous_op_date,v_op_date) > 1 OR v_rep_pattern = 1) AND previous_rep_pattern >= p_start_martingale THEN
				IF previous_rep_pattern > (p_start_martingale + 3)  THEN SET op_profit = - (p_1_op_value + p_2_op_value + p_3_op_value + p_4_op_value);
				ELSEIF previous_rep_pattern = p_start_martingale THEN SET op_profit = p_1_op_value * payout / 100;
				ELSEIF previous_rep_pattern = p_start_martingale + 1 THEN SET op_profit = p_2_op_value * payout / 100 - p_1_op_value;
				ELSEIF previous_rep_pattern = p_start_martingale + 2 THEN SET op_profit = p_3_op_value * payout / 100 - p_1_op_value - p_2_op_value;
				ELSEIF previous_rep_pattern = p_start_martingale + 3 THEN SET op_profit = p_4_op_value * payout / 100 - p_1_op_value - p_2_op_value - p_3_op_value;
				ELSEIF previous_rep_pattern = p_start_martingale + 4 THEN SET op_profit = p_5_op_value * payout / 100 - p_1_op_value - p_2_op_value - p_3_op_value - p_4_op_value;		
				ELSEIF previous_rep_pattern = p_start_martingale + 5 THEN SET op_profit = p_6_op_value * payout / 100 - p_1_op_value - p_2_op_value - p_3_op_value - p_4_op_value - p_5_op_value;
			END IF;
		
				SET profit = profit + op_profit;
				IF op_profit < capital THEN SET capital = op_profit; END IF;
				
				INSERT INTO performance VALUES (v_pair, v_op_date, op_profit);

			END IF;
		END IF;
        
        SET previous_rep_pattern = v_rep_pattern;
        SET previous_op_date = v_op_date;
        
	END LOOP read_loop;
	close cur1;

-- SELECT profit;
-- SELECT p.pair, p.Date, p.Profit FROM performance p;
 SELECT p.pair, month(p.Date), sum(p.Profit) FROM performance p GROUP BY MONTH(p.Date);
-- SELECT * FROM performance;
-- SELECT capital;

END$$

DELIMITER ;

