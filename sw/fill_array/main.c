unsigned int array[8];
unsigned int i = 0x7654;
int main(void) {
    while(i < 4);
    while(1) {
        array[i % 8] = i;
        i++;
    }
    return 0;
}
