/*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
  │ TITLE: Print a message with no wait                                                         │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ DESCRIPTION:                                                                                │

  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │ REVISION HISTORY:                                                                           │
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤
  │   DATE       AUTHOR          CHANGE DESCRIPTION                                             │
  │   ────────── ─────────────── ────────────────────────────────────────────────────────────── │
      2018.11.08 bwarner         Initial Draft
  ├─────────────────────────────────────────────────────────────────────────────────────────────┤

      RAISERROR ( { msg_str | @local_variable }  
          { ,severity ,state }  
          [ ,argument [ ,...n ] ] )  
          [ WITH option [ ,...n ] ]  

      Arguments

      msg_id
      ======
      Is a user-defined error message number stored in the sys.messages catalog view 
      using sp_addmessage. Error numbers for user-defined error messages should be greater than 
      50000. When msg_id is not specified, RAISERROR raises an error message with an error 
      number of 50000.

      msg_str

      Is a user-defined message with formatting similar to the printf function in the C 
      standard library. The error message can have a maximum of 2,047 characters. 
      If the message contains 2,048 or more characters, only the first 2,044 are displayed 
      and an ellipsis is added to indicate that the message has been truncated. Note that 
      substitution parameters consume more characters than the output shows because of 
      internal storage behavior. For example, the substitution parameter of %d with an 
      assigned value of 2 actually produces one character in the message string but also 
      internally takes up three additional characters of storage. This storage requirement 
      decreases the number of available characters for message output.

      When msg_str is specified, RAISERROR raises an error message with an error number of 50000.

      msg_str is a string of characters with optional embedded conversion specifications. 
      Each conversion specification defines how a value in the argument 
      list is formatted and placed into a field at the location of the 
      conversion specification in msg_str. Conversion specifications have this format:

      % [[flag] [width] [. precision] [{h | l}]] type

      The parameters that can be used in msg_str are:

      flag

      Is a code that determines the spacing and justification of the substituted value.

      Code	Prefix or justification	Description
      - (minus)	Left-justified	Left-justify the argument value within the given field width.
      + (plus)	Sign prefix	Preface the argument value with a plus (+) or minus (-) if the 
        value is of a signed type.
      0 (zero)	Zero padding	Preface the output with zeros until the minimum width is reached. 
        When 0 and the minus sign (-) appear, 0 is ignored.
      # (number)	0x prefix for hexadecimal type of x or X	When used with the o, x, or X format,
        the number sign (#) flag prefaces any nonzero value with 0, 0x, or 0X, 
        respectively. When d, i, or u are prefaced by the number sign (#) flag, the flag is ignored.
      ' ' (blank)	Space padding	Preface the output value with blank spaces if the value is signed 
          and positive. This is ignored when included with the plus sign (+) flag.

      width

      Is an integer that defines the minimum width for the field into which the argument value 
      is placed. If the length of the argument value is equal to or longer than width, the value 
      is printed with no padding. If the value is shorter than width, the value is padded to the 
      length specified in width.

      An asterisk (*) means that the width is specified by the associated argument in the 
      argument list, which must be an integer value.

      precision

      Is the maximum number of characters taken from the argument value for string values. 
      For example, if a string has five characters and precision is 3, only the first 
      three characters of the string value are used.

      For integer values, precision is the minimum number of digits printed.

      An asterisk (*) means that the precision is specified by the associated argument in 
      the argument list, which must be an integer value.

      {h | l} type

      Is used with character types d, i, o, s, x, X, or u, and creates shortint (h) or longint (l) values.

      Type specification	Represents
      d or i	Signed integer
      o	Unsigned octal
      s	String
      u	Unsigned integer
      x or X	Unsigned hexadecimal


      @local_variable
      Is a variable of any valid character data type that contains a string formatted in the 
      same manner as msg_str. @local_variable must be char or varchar, or be able to be 
      implicitly converted to these data types.

      severity
      Is the user-defined severity level associated with this message. When using msg_id 
      to raise a user-defined message created using sp_addmessage, the severity specified 
      on RAISERROR overrides the severity specified in sp_addmessage.

      Severity levels from 0 through 18 can be specified by any user. Severity levels from 
      19 through 25 can only be specified by members of the sysadmin fixed server role or 
      users with ALTER TRACE permissions. For severity levels from 19 through 25, the WITH LOG 
      option is required. Severity levels less than 0 are interpreted as 0. Severity levels 
      greater than 25 are interpreted as 25.

\*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

-- Version with message variable

DECLARE 
    @InfoMessage VARCHAR(2047)

SET @InfoMessage = 'My immediate message'
RAISERROR(@InfoMessage, 0, 1) WITH NOWAIT



-- string litteral version

RAISERROR('__MY_MESSAGE__', 0, 1) WITH NOWAIT
