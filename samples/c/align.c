// __attribute__((aligned));
// __attribute__((aligned (4)));
// From https://www.keil.com/support/man/docs/armclang_ref/armclang_ref_chr1385461015401.htm

#include <stdint.h>
#include <stdio.h>
#include <stddef.h>

#define STR(s) #s

// Aligns on 16-byte boundary
int x __attribute__((aligned (16)));

// When no value is given, the alignment used is the maximum alignment for a scalar data type.
//   For A32, the maximum is 8 bytes.
//   For A64, the maximum is 16 bytes.
short my_array[3] __attribute__((aligned));

// Cannot decrease the alignment below the natural alignment of the type.
// Aligns on 4-byte boundary.
int my_array_reduced[3] __attribute__((aligned (2)));

// b aligns on 8-byte boundary for A32 and 16-byte boundary for A64
struct my_struct
{
	char a;
	int b __attribute__((aligned));
};

// 'aligned' on a struct member cannot decrease the alignment below the
// natural alignment of that member. b aligns on 4-byte boundary.
struct my_struct_reduced
{
	char a;
	int b __attribute__((aligned (2)));
};

// 'aligned' on a struct member cannot decrease the alignment below the
// natural alignment of that member. b aligns on 4-byte boundary.
struct my_struct_reduced_2
{
	char a;
	int b __attribute__((aligned (16)));
};

// Combine 'packed' and 'aligned' on a struct member to set the alignment for that
// member to any value. b aligns on 2-byte boundary.
struct my_struct_packed
{
	char a;
	int b __attribute__((packed)) __attribute__((aligned (2)));
};

int main() {
#define SHOW_STRUCT(t)                                                         \
  do {                                                                         \
    printf(STR(t) " is size %zd, align %zd\n", sizeof(struct t),               \
           _Alignof(struct t));                                                \
    printf("  a is at offset %zd\n", offsetof(struct t, a));                   \
    printf("  b is at offset %zd\n", offsetof(struct t, b));                   \
  } while (0)

  SHOW_STRUCT(my_struct);
  SHOW_STRUCT(my_struct_reduced);
  SHOW_STRUCT(my_struct_reduced_2);
  SHOW_STRUCT(my_struct_packed);
  return 0;
}

/* Output:
my_struct is size 32, align 16
  a is at offset 0
  b is at offset 16
my_struct_reduced is size 8, align 4
  a is at offset 0
  b is at offset 4
my_struct_reduced_2 is size 32, align 16
  a is at offset 0
  b is at offset 16
my_struct_packed is size 6, align 2
  a is at offset 0
  b is at offset 2
 */
