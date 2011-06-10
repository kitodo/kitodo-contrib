DELIMITER //
DROP PROCEDURE IF EXISTS delete_goobi_process;
CREATE PROCEDURE delete_goobi_process(IN pid INT, IN title VARCHAR(50))
BEGIN
    DELETE s, sbg
        FROM `schritte` s, `schritteberechtigtegruppen` sbg, `prozesse` p
        WHERE s.`ProzesseID`=pid AND sbg.`schritteID`=s.`SchritteID` AND p.`Titel`=title AND p.`ProzesseID`=pid;
    DELETE v, ve
        FROM `vorlagen` v, `vorlageneigenschaften` ve, `prozesse` p
        WHERE v.`ProzesseID`=pid AND ve.`vorlagenID`=v.`VorlagenID` AND p.`Titel`=title AND p.`ProzesseID`=pid;
    DELETE w, we
        FROM `werkstuecke` w, `werkstueckeeigenschaften` we, `prozesse` p
        WHERE w.`ProzesseID`=pid AND we.`werkstueckeID`=w.`WerkstueckeID` AND p.`Titel`=title AND p.`ProzesseID`=pid;
    DELETE
        FROM `prozesse`
        WHERE `ProzesseID`=pid AND `Titel`=title;
END
//
DROP PROCEDURE IF EXISTS delete_defects;
CREATE PROCEDURE delete_defects()
BEGIN
    DECLARE pid INT;
    DECLARE title VARCHAR(50);
    DECLARE done INT DEFAULT 0;
    DECLARE defects CURSOR FOR
        SELECT p.ProzesseID as VorgangsID, p.Titel as VorgangsTitel
        FROM prozesse p, Projekte P
        WHERE P.ProjekteID = p.ProjekteID AND  p.IstTemplate = 0 AND P.Titel = 'Testprojekt'
        ORDER BY VorgangsID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN defects;
    
    read_loop: LOOP
        FETCH defects INTO pid, title;
        IF done THEN
            LEAVE read_loop;
        END IF;
        CALL delete_goobi_process(pid, title); 
    END LOOP;

    CLOSE defects;
 END
//
DELIMITER ;
