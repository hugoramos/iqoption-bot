USE `tocasystem_dev`;
DROP procedure IF EXISTS `fill_repetion_pattern`;

DELIMITER $$
USE `tocasystem_dev`$$
CREATE DEFINER=`tocasystem`@`%` PROCEDURE `fill_repetion_pattern`(IN p_pair VARCHAR(44))
BEGIN

    -- update forex set size = close - open where pair like 'USDCHF';

	DECLARE v_id, consecutive_times_previous_row, new_rep_pattern INT;
    DECLARE v_size, size_previous_row DECIMAL(18,8);
    DECLARE v_pair VARCHAR(44);
	DECLARE done INT DEFAULT FALSE;  

	DECLARE cur1 CURSOR FOR SELECT id, pair, size from forex WHERE pair LIKE p_pair ORDER BY id; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;  

	open cur1;

	read_loop: loop
		fetch cur1 into v_id, v_pair, v_size;	
		IF done THEN
			LEAVE read_loop;
		END IF;
        
		SET size_previous_row = 0;
		SET consecutive_times_previous_row = 0;
	
		SET size_previous_row = (SELECT size FROM forex WHERE id = (v_id - 1) AND pair LIKE v_pair LIMIT 1);  
		SET consecutive_times_previous_row = (SELECT rep_pattern FROM forex WHERE id = (v_id - 1) AND pair LIKE v_pair LIMIT 1);  		
		
		IF size_previous_row > 0 AND v_size > 0 THEN
			SET new_rep_pattern = consecutive_times_previous_row + 1;
		ELSEIF size_previous_row < 0 AND v_size < 0 THEN
			SET new_rep_pattern = consecutive_times_previous_row + 1;
		ELSE	
			SET new_rep_pattern = 1;
		END IF;	

		-- SELECT v_id, v_pair, v_size, new_rep_pattern, size_previous_row, consecutive_times_previous_row;	
	
		UPDATE forex SET rep_pattern = new_rep_pattern WHERE id = v_id;
            
	END LOOP read_loop;
	close cur1;
END$$

DELIMITER ;

