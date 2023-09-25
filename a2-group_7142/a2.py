"""
# This code is provided solely for the personal and private use of students 
# taking the CSC343H course at the University of Toronto. Copying for purposes 
# other than this use is expressly prohibited. All forms of distribution of 
# this code, including but not limited to public repositories on GitHub, 
# GitLab, Bitbucket, or any other online platform, whether as given or with 
# any changes, are expressly prohibited. 
"""

from typing import Optional
import psycopg2 as pg
import datetime
import math

class Assignment2:

    ##### DO NOT MODIFY THE CODE BELOW. #####

    def __init__(self) -> None:
        """Initialize this class, with no database connection yet.
        """
        self.db_conn = None

    
    def connect_db(self, url: str, username: str, pword: str) -> bool:
        """Connect to the database at url and for username, and set the
        search_path to "air_travel". Return True iff the connection was made
        successfully.

        >>> a2 = Assignment2()
        >>> # This example will make sense if you change the arguments as
        >>> # appropriate for you.
        >>> a2.connect_db("csc343h-<your_username>", "<your_username>", "")
        True
        >>> a2.connect_db("test", "postgres", "password") # test doesn't exist
        False
        """
        try:
            self.db_conn = pg.connect(dbname=url, user=username, password=pword,
                                      options="-c search_path=air_travel")
        except pg.Error:
            return False

        return True

    def disconnect_db(self) -> bool:
        """Return True iff the connection to the database was closed
        successfully.

        >>> a2 = Assignment2()
        >>> # This example will make sense if you change the arguments as
        >>> # appropriate for you.
        >>> a2.connect_db("csc343h-<your_username>", "<your_username>", "")
        True
        >>> a2.disconnect_db()
        True
        """
        try:
            self.db_conn.close()
        except pg.Error:
            return False

        return True

    ##### DO NOT MODIFY THE CODE ABOVE. #####

    # ----------------------- Airline-related methods ------------------------- */

    def book_seat(self, pass_id: int, flight_id: int, seat_class: str) -> Optional[bool]:
        """Attempts to book a flight for a passenger in a particular seat class. 
        Does so by inserting a row into the Booking table.
        
        Read the handout for information on how seats are booked.

        Parameters:
        * pass_id - id of the passenger
        * flight_id - id of the flight
        * seat_class - the class of the seat

        Precondition:
        * seat_class is one of "economy", "business", or "first".
        
        Return: 
        * True iff the booking was successful.
        * False iff the seat can't be booked, or if the passenger or flight cannot be found.
        """
        try:
            cursor = self.db_conn.cursor()
            #Find the capacity of the wanted plane and seat class
            cursor.execute("""
                SELECT capacity_economy, capacity_business, capacity_first
                FROM Flight, Plane
                WHERE Flight.plane = Plane.tail_number
                    AND FLight.id = %s""", (flight_id,))
            all_capacity = cursor.fetchall()
            if not all_capacity:
                return False

            #Find the amount already booked
            cursor.execute("""
                SELECT count(Booking.id)
                FROM Booking 
                WHERE Booking.flight_id = %s AND seat_class = %s
                GROUP BY Booking.flight_id
            """, (flight_id, seat_class))
            num_booked = cursor.fetchall()
            if not num_booked:
                num_booked = [(0,)]

            #Find the current max booking id
            cursor.execute("""
                SELECT max(id)
                From Booking""")
            max_booking_id = cursor.fetchall()
            if max_booking_id[0][0] is None:
                max_booking_id = [(0,)]

            #Find current price of all seat classes for this flight
            cursor.execute("""
                SELECT economy, business, first
                FROM Price
                WHERE Price.flight_id = %s""", (flight_id,))
            current_prices = cursor.fetchall()
            if not current_prices:
                return False

            first_rows = math.ceil(all_capacity[0][2] / 6.0)
            business_rows = math.ceil(all_capacity[0][1] / 6.0) 
            economy_rows = math.ceil(all_capacity[0][0] / 6.0) 

            if seat_class == 'economy':

                economy_capacity = all_capacity[0][0]
                #still not fully booked economy class
                if num_booked[0][0] < economy_capacity:

                    #calculate the position of next available seat
                    assigned_row = math.floor(num_booked[0][0] / 6.0)
                    seat_pos = num_booked[0][0] - 6 * assigned_row

                    #insert into Booking the new tuple
                    booking_id = max_booking_id[0][0] + 1
                    curr_time = self._get_current_timestamp()
                    curr_price = current_prices[0][0]
                    seat_row = assigned_row + 1 + first_rows + business_rows
                    letter = chr(ord('A') + seat_pos)

                    cursor.execute(f"""
                        INSERT INTO Booking values ({booking_id}, 
                                                    {pass_id},
                                                    {flight_id},
                                                    TIMESTAMP '{curr_time}',
                                                    {curr_price},
                                                    '{seat_class}',
                                                    {seat_row},
                                                    '{letter}')
                    """)
                    self.db_conn.commit()
                    return True

                #within 10 exceeds
                if num_booked[0][0] >= economy_capacity and num_booked[0][0] < economy_capacity + 10:

                    #insert into Booking the new tuple
                    booking_id = max_booking_id[0][0] + 1
                    curr_time = self._get_current_timestamp()
                    curr_price = current_prices[0][0]

                    cursor.execute(f"""
                        INSERT INTO Booking values ({booking_id}, 
                                                    {pass_id},
                                                    {flight_id},
                                                    TIMESTAMP '{curr_time}',
                                                    {curr_price},
                                                    '{seat_class}',
                                                    NULL,
                                                    NULL)
                    """)
                    self.db_conn.commit()
                    return True
                return False

            if seat_class == 'business':
                business_capacity = all_capacity[0][1]
                #still not fully booked economy class
                if num_booked[0][0] < business_capacity:
                    #calculate the position of next available seat
                    assigned_row = math.floor(num_booked[0][0] / 6.0)
                    seat_pos = num_booked[0][0] - 6 * assigned_row

                    #insert into Booking the new tuple
                    booking_id = max_booking_id[0][0] + 1
                    curr_time = self._get_current_timestamp()
                    curr_price = current_prices[0][0]
                    seat_row = assigned_row + 1 + first_rows
                    letter = chr(ord('A') + seat_pos)

                    cursor.execute(f"""
                        INSERT INTO Booking values ({booking_id}, 
                                                    {pass_id},
                                                    {flight_id},
                                                    TIMESTAMP '{curr_time}',
                                                    {curr_price},
                                                    '{seat_class}',
                                                    {seat_row},
                                                    '{letter}')
                    """)
                    self.db_conn.commit()
                    return True
            
            if seat_class == 'first':
                first_capacity = all_capacity[0][2]
                #still not fully booked economy class
                if num_booked[0][0] < first_capacity:
                    #calculate the position of next available seat
                    assigned_row = math.floor(num_booked[0][0] / 6.0)
                    seat_pos = num_booked[0][0] - 6 * assigned_row

                    #insert into Booking the new tuple
                    booking_id = max_booking_id[0][0] + 1
                    curr_time = self._get_current_timestamp()
                    curr_price = current_prices[0][0]
                    seat_row = assigned_row + 1
                    letter = chr(ord('A') + seat_pos)

                    cursor.execute(f"""
                        INSERT INTO Booking values ({booking_id}, 
                                                    {pass_id},
                                                    {flight_id},
                                                    TIMESTAMP '{curr_time}',
                                                    {curr_price},
                                                    '{seat_class}',
                                                    {seat_row},
                                                    '{letter}')
                    """)
                    self.db_conn.commit()
                    return True
                  
        except pg.Error:
            return None


    def upgrade(self, flight_id: int) -> Optional[int]:
        """Attempts to upgrade overbooked economy passengers to business class
        or first class (in that order until each seat class is filled).
        Does so by altering the database records for the bookings such that the
        seat and seat_class are updated if an upgrade can be processed.
        
        Upgrades should happen in order of earliest booking timestamp first.
        If economy passengers are left over without a seat (i.e. not enough higher class seats), 
        remove their bookings from the database.
        
        Parameters:
        * flight_id - the flight to upgrade passengers in
        
        Precondition: 
        * flight_id exists in the database (a valid flight id).
        
        Return: 
        * The number of passengers upgraded.
        """
        try:
            cursor = self.db_conn.cursor()
            #Find all bookings that needs an upgrade
            cursor.execute("""
                SELECT *
                FROM Booking
                WHERE row IS NULL AND letter IS NULL AND Booking.flight_id = %s
                ORDER BY datetime
            """, (flight_id,))
            need_upgrade = cursor.fetchall()
            if not need_upgrade:
                return 0

            #Find the amount of business class seats left
            cursor.execute("""
                SELECT count(Booking.id)
                FROM Booking 
                WHERE Booking.flight_id = %s AND seat_class = %s
                GROUP BY Booking.flight_id
            """, (flight_id, 'business'))
            business_booked = cursor.fetchall()
            if not business_booked:
                business_booked = [(0,)]

            business_booked_num = business_booked[0][0]
            #Find the amount of first class seats left
            cursor.execute("""
                SELECT count(Booking.id)
                FROM Booking 
                WHERE Booking.flight_id = %s AND seat_class = %s
                GROUP BY Booking.flight_id
            """, (flight_id, 'first'))
            first_booked = cursor.fetchall()
            if not first_booked:
                first_booked = [(0,)]

            first_booked_num = first_booked[0][0]

            #Find the number of first class and business class seats left
            cursor.execute("""
                SELECT capacity_business, capacity_first
                FROM Flight, Plane
                WHERE Flight.plane = Plane.tail_number AND Flight.id = %s
            """, (flight_id,))
            all_capacity = cursor.fetchall()
            if not all_capacity:
                return 0
            
            first_left = all_capacity[0][1] - first_booked_num
            business_left = all_capacity[0][0] - business_booked_num

            if first_left == 0 and business_left == 0:
                return 0

            first_rows = math.ceil(all_capacity[0][1] / 6.0)
            business_rows = math.ceil(all_capacity[0][0] / 6.0)

            success = 0
            #start with business class
            for ticket in need_upgrade:
                ticket_id = ticket[0]

                #delete the original booking info
                cursor.execute("""
                    DELETE FROM Booking
                    WHERE Booking.id = %s        
                """, (ticket_id,))
                self.db_conn.commit()

                #check if business still have seats left
                if business_left > 0:

                    #calculate new seat position
                    assigned_row = math.floor(business_booked_num / 6.0)
                    seat_pos = business_booked_num - 6 * assigned_row

                    #insert new info into booking
                    booking_id = ticket[0]
                    pass_id = ticket[1]
                    curr_time = ticket[3]
                    curr_price = ticket[4]
                    seat_class = 'business'
                    seat_row = assigned_row + 1 + first_rows
                    letter = chr(ord('A') + seat_pos)

                    cursor.execute(f"""
                        INSERT INTO Booking values ({booking_id}, 
                                                    {pass_id},
                                                    {flight_id},
                                                    TIMESTAMP '{curr_time}',
                                                    {curr_price},
                                                    '{seat_class}',
                                                    {seat_row},
                                                    '{letter}')
                    """)
                    self.db_conn.commit()
                    
                    business_left -= 1
                    business_booked_num += 1
                    success += 1
                elif business_left <= 0 and first_left > 0:

                    #calculate new seat position
                    assigned_row = math.floor(first_booked_num / 6.0)
                    seat_pos = first_booked_num - 6 * assigned_row

                    #insert new info into booking
                    booking_id = ticket[0]
                    pass_id = ticket[1]
                    curr_time = ticket[3]
                    curr_price = ticket[4]
                    seat_class = 'first'
                    seat_row = assigned_row + 1
                    letter = chr(ord('A') + seat_pos)

                    cursor.execute(f"""
                        INSERT INTO Booking values ({booking_id}, 
                                                    {pass_id},
                                                    {flight_id},
                                                    TIMESTAMP '{curr_time}',
                                                    {curr_price},
                                                    '{seat_class}',
                                                    {seat_row},
                                                    '{letter}')
                    """)
                    self.db_conn.commit()
                    
                    first_left -= 1
                    first_booked_num += 1
                    success += 1
            return success

        except pg.Error:
            return None


# ----------------------- Helper methods below  ------------------------- */
    

    # A helpful method for adding a timestamp to new bookings.
    def _get_current_timestamp(self):
        """Return a datetime object of the current time, formatted as required
        in our database.
        """
        return datetime.datetime.now().replace(microsecond=0)

   
    ## Add more helper methods below if desired.



# ----------------------- Testing code below  ------------------------- */

def sample_testing_function() -> None:
    a2 = Assignment2()
    # TODO: Change this to connect to your own database:
    print(a2.connect_db("csc343h-zhouj195", "zhouj195", ""))
    # TODO: Test one or more methods here.

## You can put testing code in here. It will not affect our autotester.
if __name__ == '__main__':
    # TODO: Put your testing code here, or call testing functions such as
    # this one:
    sample_testing_function()




