
//Initialization sequence, 4bit mode, reversed nibbles
byte initial[] = {0x3, 0x3, 0x3, 0x2, 0x2, 0x8, 0x0, 0xC, 0x0, 0x1, 0x0, 0x6};

//PINOUT OPTION B (Reverse = 0): D7 to P3, D6 to P2, D5 to P1, D4 to P0 (Default)
//PINOUT OPTION A (Reverse = 1): D7 to P0, D6 to P1, D5 to P2, D4 to P3 
//Use 1 in functions to reverse data before sending

byte lower_Nibble_Mask = 0xF0;  //Mask to delete lower nibble of PORTD (nibble = 1/2 byte) (1111 0000)
byte upper_Nibble_Mask = 0x0F;  //Mask to delete upper nibble (0000 1111)
byte data_Mask         = 0x30;  //Mask to turn HIGH PD4 and PD5 (00110000)
byte instruction_Mask  = 0x10;  //Mask to turn HIGH PD4 (00010000)

void setup() {

  DDRD = B11111111;                 //Set PD6 as output, rest as inputs
  PORTD = B00000000;                //Set PB0 to PB7 to LOw
  delay(3000);
  lcd_Initialize();                 //Initialize display
  

}

void loop() {
  
  delay(1000);
  lcd_Clear_Display();
  delay(1000);
  lcd_Send_String("Hello World");
  delay(1000);
  lcd_Change_Adress(0x40);
  delay(1000);
  lcd_Send_String("Hello World");
  delay(1000);
  lcd_Clear_Display();
  delay(1000);
  lcd_animation();
  delay(1000);
  lcd_Clear_Display();
  delay(1000);
  lcd_Send_String_Fast("Hello World");
  lcd_Change_Adress(0x40);
  lcd_Send_String_Fast("Hello World");
  
}

void lcd_Initialize() {             //Send initialization sequence

  uint8_t n;

  delay(30);                        //Wait for the LCD to power up

  for (n = 0; n < 12; n++) {        //Send initialization sequence
    PORTD = initial[n];             //Write nibble sequence into PORT
    delay(300);
    PORTD |= _BV(PD4);
    delay(100);                       //Delays must be used not to overflow the LCD
    PORTD &= ~_BV(PD4);
    delay(100);
  }

}


void lcd_Clear_Display() {          //Clears display (sends intruction 0000 0001 (reversed))

  lcd_Send_Instruction(0x01, 0);
  delay(1000);                         //LCD can take up to 2ms to refresh

  //Remember, if you chose the second pinout use 0 as second
}


void lcd_Change_Adress(byte adress) {      //Moves cursor to selected adress (place in the screen)

  adress |= 0x80;                          //DB7 must be HIGH
  lcd_Send_Instruction(adress, 0);

  //First line: 0x00, 0x01, 0x02... to 0x0F
  //Second Line: 0x40, 0x41, 0x42... to 0x4F

}

//Prints centered text on desired line (also displays <> if line is selected)
void lcd_Send_String(char string[]) {

  uint8_t n;
  uint8_t siz;
  
  siz = strlen(string);

    for (n = 0; n < siz; n++) {

      lcd_Send_Data(string[n], 0);

    }

}

void lcd_Send_String_Fast(char string[]) {

  uint8_t n;
  uint8_t siz;
  
  siz = strlen(string);

    for (n = 0; n < siz; n++) {

      lcd_Send_Data_Fast(string[n], 0);

    }

}

//4 bit data sender
void lcd_Send_Data(byte data, uint8_t reverse) {

  if (reverse == 1) {
    data = (data & 0xCC) >> 2 | (data & 0x33) << 2;    //order to match PORTD pin disposition
    data = (data & 0xAA) >> 1 | (data & 0x55) << 1;    //(e.g: H = 0100 1000 -> 0001 0010)
  }

  PORTD &= lower_Nibble_Mask;
  PORTD |= data >> 4;                      //Puts upper nibble in place and turns on PD4 and PD5
  delay(300);
  PORTD |= _BV(PD5);
  PORTD |= _BV(PD4);
  delay(100);
  PORTD &= ~_BV(PD4);
  PORTD &= ~_BV(PD5);
  delay(100);

  PORTD &= lower_Nibble_Mask;
  PORTD |= data & upper_Nibble_Mask;
  delay(300);
  PORTD |= _BV(PD5);
  PORTD |= _BV(PD4);
  delay(100);
  PORTD &= ~_BV(PD4);
  PORTD &= ~_BV(PD5);
  delay(100);

}


void lcd_Send_Data_Fast(byte data, uint8_t reverse) {

  if (reverse == 1) {
    data = (data & 0xCC) >> 2 | (data & 0x33) << 2;    //order to match PORTD pin disposition
    data = (data & 0xAA) >> 1 | (data & 0x55) << 1;    //(e.g: H = 0100 1000 -> 0001 0010)
  }

  PORTD &= lower_Nibble_Mask;
  PORTD |= data >> 4;                      //Puts upper nibble in place and turns on PD4 and PD5
  PORTD |= _BV(PD5);
  PORTD |= _BV(PD4);
  delayMicroseconds(200);
  PORTD &= ~_BV(PD4);
  PORTD &= ~_BV(PD5);
  delayMicroseconds(200);

  PORTD &= lower_Nibble_Mask;
  PORTD |= data & upper_Nibble_Mask;
  PORTD |= _BV(PD5);
  PORTD |= _BV(PD4);
  delayMicroseconds(200);
  PORTD &= ~_BV(PD4);
  PORTD &= ~_BV(PD5);
  delayMicroseconds(200);

}

//4 bit instruction sender
void lcd_Send_Instruction(byte instruction, uint8_t reverse) {

  if (reverse == 1) {
    instruction = (instruction & 0xCC) >> 2 | (instruction & 0x33) << 2;    //order to match PORTD pin disposition
    instruction = (instruction & 0xAA) >> 1 | (instruction & 0x55) << 1;    //(e.g: H = 0100 1000 -> 0001 0010)
  }

  PORTD &= lower_Nibble_Mask;
  PORTD |= instruction >> 4;                      //Puts upper nibble in place and turns on PD4 and PD5
  delay(300);
  PORTD |= _BV(PD4);
  delay(100);
  PORTD &= ~_BV(PD4);
  delay(100);

  PORTD &= lower_Nibble_Mask;
  PORTD |= instruction & upper_Nibble_Mask;
  delay(300);
  PORTD |= _BV(PD4);
  delay(100);
  PORTD &= ~_BV(PD4);
  delay(100);
}

void lcd_animation(){

  uint8_t n;
  
  lcd_Send_Data('[',0);
  lcd_Change_Adress(0xF);
  lcd_Send_Data(']',0);
  lcd_Change_Adress(0x1);

  for(n=0;n<14;n++){
  lcd_Send_Data(0xFF,0);
  }
  
  lcd_Change_Adress(0x40);
  
  lcd_Send_Data_Fast('[',0);
  lcd_Change_Adress(0x4F);
  lcd_Send_Data_Fast(']',0);
  lcd_Change_Adress(0x41);

  for(n=0;n<14;n++){
  lcd_Send_Data_Fast(0xFF,0);
  }

}





