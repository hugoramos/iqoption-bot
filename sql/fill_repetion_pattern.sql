DROP procedure IF EXISTS `fill_repetion_pattern`;

DELIMITER $$
CREATE PROCEDURE `fill_repetion_pattern`(IN p_pair VARCHAR(44))
BEGIN

	DECLARE v_id, consecutive_times_previous_row, new_rep_pattern, count INT;
    DECLARE v_size, size_previous_row DECIMAL(18,8);
    DECLARE v_pair VARCHAR(44);
    DECLARE v_time, time_previous_row DATETIME;
	DECLARE done INT DEFAULT FALSE;  

-- 	DECLARE cur1 CURSOR FOR SELECT id, pair, size, time from forex WHERE pair LIKE p_pair and id > 1200005 ORDER BY id limit 5; 
	DECLARE cur1 CURSOR FOR SELECT id, pair, size, time from forex WHERE pair LIKE p_pair ORDER BY id; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;  

	SET count = 0;

	open cur1; 

	read_loop: loop
		fetch cur1 into v_id, v_pair, v_size, v_time;	
		IF done THEN
			LEAVE read_loop;
		END IF;
        
		SET size_previous_row = 0;
		SET time_previous_row = '2000-01-01';
		SET consecutive_times_previous_row = 0;
        	
		IF count > 0 THEN
			SELECT size, time, rep_pattern INTO size_previous_row, time_previous_row, consecutive_times_previous_row FROM forex WHERE id = (v_id - 1) AND pair LIKE v_pair LIMIT 1;  
		END IF;
        
        IF count % 20000 = 0 THEN
			select count;
		END IF;
        
--         IF count = 0 OR DATE(time_previous_row) != DATE(v_time) THEN	
        IF count = 0 THEN	
			SET new_rep_pattern = 1;
		ELSE
			-- select 'entrou else';
			IF size_previous_row > 0 AND v_size > 0 THEN
				SET new_rep_pattern = consecutive_times_previous_row + 1;
			ELSEIF size_previous_row < 0 AND v_size < 0 THEN
				SET new_rep_pattern = consecutive_times_previous_row + 1;
			ELSE	
				SET new_rep_pattern = 1;
			END IF;	
		END IF;

		UPDATE forex SET rep_pattern = new_rep_pattern WHERE id = v_id;
            
		SET count = count + 1;        

	END LOOP read_loop;
	close cur1;
            
END$$

DELIMITER ;

