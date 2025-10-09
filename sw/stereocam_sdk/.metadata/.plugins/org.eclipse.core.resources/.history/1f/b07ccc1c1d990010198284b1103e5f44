/*
 * log.h
 *
 *  Created on: 18 џэт. 2023 у.
 *      Author: buren
 */

#ifndef USER_LOG_H_
#define USER_LOG_H_

#include <stdio.h>

//#define LOG_ENABLED

#ifdef LOG_ENABLED

#	define LOG(format,args...)				\
			do{								\
				printf(format, ## args);	\
			}while(0)						\

#	else

#	define LOG(format,args...)		\
		do{} while(0)						\

#	endif //LOG_ENABLED


#endif /* USER_LOG_H_ */
