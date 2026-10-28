// See LemnaCatch.h.
#import <Foundation/Foundation.h>
#include <string.h>
#include "LemnaCatch.h"

int LemnaCatch(void (__attribute__((noescape)) ^block)(void), char *message, unsigned long size) {
    @try {
        block();
        return 0;
    } @catch (NSException *e) {
        if (message && size > 0) {
            NSString *text = [NSString stringWithFormat:@"%@: %@", e.name, e.reason];
            strlcpy(message, text.UTF8String ?: "", size);
        }
        return 1;
    }
}
