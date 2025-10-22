import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPasswordField;
import javax.swing.JTextField;
import java.util.Objects;
import java.util.Scanner;

public class DBConn {

    String jdbcUrl = "jdbc:postgresql://localhost:63333/postgres";
    Connection conn;

    //This function connects the user to the database initially. 
    //Note that it's 1:1 with what lecture 5.5 showed. 
    public Connection getDBConnection() throws SQLException {

        if (conn == null) {
            // Display a message to get the password from the user
            JLabel label = new JLabel("Postgres Username: ");
            JTextField jtf = new JTextField();
            JLabel label2 = new JLabel("Postgres Password:");
            JPasswordField jpf = new JPasswordField();
            JOptionPane.showConfirmDialog(null,
                    new Object[]{label, jtf, label2, jpf},
                    "Password:", JOptionPane.OK_CANCEL_OPTION);
            String password = String.valueOf(jpf.getPassword());
            conn = DriverManager.getConnection(jdbcUrl, jtf.getText(), password);
        }
        conn.setAutoCommit(true);
        return conn;
    }

    public static void main(String[] args) throws Exception {
        //Creating a scanner to get user input
        Scanner input_reader = new Scanner(System.in);

        //Initializing DB connection with the function getDBConnection()
        DBConn q = new DBConn();
        try{q.getDBConnection();}
        catch (Exception err){
            err.printStackTrace();
        }

        //Main program loop
        while(true) {
            System.out.println("Please type '1' or '2' to execute the following: \n" +
                               "1. Check if a guest is checked in at a hotel \n" +
                               "2. Find all the average number of guests per hotel per week");
            String user_input = input_reader.nextLine();

            //Case 1, check if a given guest is checked in
            if (Objects.equals(user_input, "1")){

                //Scanning in both names
                System.out.println("Please enter the guest's first name:");
                String firstName = input_reader.nextLine();
                System.out.println("Please enter the guest's last name:");
                String lastName = input_reader.nextLine();

                //Emptiness check
                if(Objects.equals(firstName, "") || Objects.equals(lastName, "")){
                    System.out.println("Please make sure both names aren't empty");
                    continue;
                }

                System.out.println(checkForGuest(q.conn, firstName, lastName));
                firstName = null;
                lastName = null;
            }

            //Case 2, check average number of weekly guests
            else if(Objects.equals(user_input, "2")){
                System.out.println(FindAvgGuests(q.conn));
            }
            else{
                System.out.println("Error, please type either '1' or '2'");
            }
            user_input = null;
        }
    }

    //Checks if the guest is currently staying at the hotel (indexes for the current date and compares their check in/out times)
    public static boolean checkForGuest(Connection q, String firstName, String lastName) throws SQLException {
    	//Main SQL string to be input
		String sql_input = """
            SELECT EXISTS (
                SELECT 1
                FROM guest g
                JOIN booking b ON g.Wristband_ID = b.Guest_ID
                WHERE g.First_Name = ? AND g.Last_Name = ?
                AND CURRENT_DATE <@ b.Booking_Range
            );
                """;
        //Attempting to use the SQL input through the established connection q
        try (var stmt = q.prepareStatement(sql_input)) {
            stmt.setString(1, firstName);
            stmt.setString(2, lastName);
            try (var rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getBoolean(1);
                }
            }
        }
        return false;
    }

    //Prints average number of guests per week per hotel
    public static String FindAvgGuests(Connection q) throws SQLException {
        StringBuilder result = new StringBuilder();
        String sql = """
        SELECT 
            b.address AS hotel_address,
            ROUND(COUNT(DISTINCT b.guest_id) * 1.0 / COUNT(DISTINCT EXTRACT(WEEK FROM lower(b.booking_range))), 2) 
            AS avg_guests_per_week
            FROM 
            booking b
            GROUP BY 
            b.address;
        """;

        try (var stmt = q.prepareStatement(sql);
             var rs = stmt.executeQuery()) {

            while (rs.next()) {
                result.append("Hotel Address: ").append(rs.getString("hotel_address"))
                        .append(", Avg Guests/Week: ").append(rs.getDouble("avg_guests_per_week"))
                        .append("\n");
            }
        }
        return result.toString();
    }

}
