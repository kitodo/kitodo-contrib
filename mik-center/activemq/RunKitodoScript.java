/*
 * Licensed under the Apache License, Version 2.0, see:
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under that license is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 */
package org.kitodo.contrib.mik_center.activemq;

/* Dependencies:
 *   •  geronimo-jms_1.1_spec
 *   •  geronimo-j2ee-management_1.1_spec
 *   •  activemq-core
 *   •  log4j-api
 *   •  log4j-core
 *   •  log4j-slf4j-impl
 *   •  slf4j-api
 */

import static java.lang.System.out;
import static java.lang.System.exit;
import java.lang.reflect.*;
import java.util.*;

import javax.jms.*;
import static javax.jms.Session.AUTO_ACKNOWLEDGE;

import org.apache.activemq.*;
import org.apache.activemq.command.*;

public class RunKitodoScript {
    static final int EXIT_OK = 0;
    static final int EXIT_USAGE = 64;
    static final int EXIT_SOFTWARE = 70;
    static final int EXIT_OS_ERROR = 71;

    static final boolean NON_TRANSACTED = false;

    /* Parameters: Active MQ host, queue name, Kitodo-Script command, [process-id,
     *             [process-id, [process-id, [...
     * 
     * Example: "tcp://localhost:61616" "KitodoProduction.KitodoScript.Queue"
     *          "action:exportDms exportImages:true" 42
     */
    public static void main(String[] args) {
        try {
            List<String> processes = (args.length > 3)?
                Arrays.asList(args).subList(3, args.length) : Collections.emptyList();

            // check arguments
            if (args.length < 3 || !processes.stream().allMatch(λ-> λ.matches("\\d+")))
            {
                out.print("Parameters: Active MQ host, queue name, ");
                out.println("Kitodo-Script command, [process-id,");
                out.println("\t    [process-id, [process-id, [...");
                exit(EXIT_USAGE);
            }

            // connect to server
            ConnectionFactory connector = new ActiveMQConnectionFactory(args[0]);
            Connection connection = connector.createConnection();
            connection.start();
            Session session = connection.createSession(NON_TRANSACTED, AUTO_ACKNOWLEDGE);
            Destination destination = session.createQueue(args[1]);
            MessageProducer producer = session.createProducer(destination);

            // create message
            MapMessage message = session.createMapMessage();
            message.setString("script", args[2]);
            if (!processes.isEmpty()) message.setObject("processes", processes);
            message.setString("id", messageId(message));

            // send message
            producer.send(message);

            // shut down
            session.close();
            connection.close();

        // error barrier
        } catch (Exception e) {
            e.printStackTrace();
            exit(EXIT_SOFTWARE);
        } catch (Error e) {
            e.printStackTrace();
            exit(EXIT_OS_ERROR);
        }
        exit(EXIT_OK);
    }

    static String messageId(MapMessage message) throws NoSuchFieldException, IllegalAccessException {
        Field map = ActiveMQMapMessage.class.getDeclaredField("map");
        map.setAccessible(true);
        return map.get(message).toString().replaceFirst("^\\{(.*)\\}$", "RunKitodoScript: $1");
    }
}
