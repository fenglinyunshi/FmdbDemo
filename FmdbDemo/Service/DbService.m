//
//  DbService.m
//  FmdbDemo
//
//  Created by ZhengXiankai on 15/7/21.
//  Copyright (c) 2015年 ZhengXiankai. All rights reserved.
//

#import "DbService.h"
#import <objc/runtime.h>
#import "FMDB.h"
#import "ColumnPropertyMappingDelegate.h"
#import "FMEncryptDatabaseQueue.h"
#import "PersonModel.h"

@interface DbService ()
{
    FMDatabaseQueue *_queue;
}

@end

@implementation DbService

- (instancetype)initWithPath:(NSString *)path encrypt:(BOOL)isEncrypted
{
    if (self = [super init]) {
        if (isEncrypted) {
            _queue = [FMEncryptDatabaseQueue databaseQueueWithPath:path];
        } else {
            _queue = [FMDatabaseQueue databaseQueueWithPath:path];
        }
    }
    
    return self;
}

- (BOOL)executeUpdate:(NSString *)sql param:(NSArray *)param
{
    __block BOOL result = NO;
    [_queue inDatabase:^(FMDatabase *db) {
        if (param && param.count > 0) {
            result = [db executeUpdate:sql withArgumentsInArray:param];
        } else {
            result = [db executeUpdate:sql];
        }
    }];
    
    return result;
    
 
}

- (id)executeScalar:(NSString *)sql param:(NSArray *)param
{
    __block id result;
    
    [_queue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:param];
        if ([rs next]) {
            result = rs[0];
        } else {
            result = 0;
        }
        [rs close];
    }];
    return result;
}

- (NSInteger)rowCount:(NSString *)tableName
{
    NSNumber *number = (NSNumber *)[self executeScalar:[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", tableName] param:nil];
    return [number longValue];
}

#pragma mark -
#pragma mark -- 自动创建model查询方法
- (NSArray *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)args modelClass:(Class)modelClass
{
    return [self executeQuery:sql withArgumentsInArray:args modelClass:modelClass performBlock:nil];
}

- (NSArray *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)args modelClass:(Class)modelClass performBlock:(void (^)(id model, FMResultSet *rs))block
{
    __block NSMutableArray *models = [NSMutableArray array];
    
    [_queue inDatabase:^(FMDatabase *db) {
        NSDictionary *mapping = nil;
        
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:args];
        while ([rs next]) {
            id model = [[modelClass alloc] init];
            if(!mapping && [model conformsToProtocol:@protocol(ColumnPropertyMappingDelegate)]) {
                //实现了列-属性转换协议
                mapping = [model columnPropertyMapping];
            }
            
            for (int i = 0; i < [rs columnCount]; i++) {
                //列名
                NSString *columnName = [rs columnNameForIndex:i];
                //进行数据库列名到model之间的映射转换，拿到属性名
                NSString *propertyName;
                
                if(mapping) {
                    propertyName = mapping[columnName];
                    if (propertyName == nil) {
                        //如果映射未定义，则视为相同
                        propertyName = columnName;
                    }
                } else {
                    propertyName = columnName;
                }
                
                objc_property_t objProperty = class_getProperty(modelClass, propertyName.UTF8String);
                //如果属性不存在，则不操作
                if (objProperty) {
                    if(![rs columnIndexIsNull:i]) {
                        [self setProperty:model value:rs columnName:columnName propertyName:propertyName property:objProperty];
                    }
                }
                
                NSAssert(![propertyName isEqualToString:@"description"], @"description为自带方法，不能对description进行赋值，请使用其他属性名或请ColumnPropertyMappingDelegate进行映射");
            }
            
            //执行自定义操作
            if (block) {
                block(model, rs);
            }
            [models addObject:model];
        }
        
        [rs close];
    }];
    return models;
}


/**
 *  解析结果集（models）
 */
- (NSArray *)resultForModels:(FMResultSet *)rs modelClass:(Class)modelClass
{
    return [self resultForModels:rs modelClass:modelClass performBlock:nil];
}

- (NSArray *)resultForModels:(FMResultSet *)rs modelClass:(Class)modelClass performBlock:(void (^)(id model, FMResultSet *rs))block;
{
    NSDictionary *mapping = nil;
    
    NSMutableArray *models = [NSMutableArray array];
    while ([rs next]) {
        id model = [[modelClass alloc] init];
        if(!mapping && [model conformsToProtocol:@protocol(ColumnPropertyMappingDelegate)]) {
            //实现了列-属性转换协议
            mapping = [model columnPropertyMapping];
        }
        
        for (int i = 0; i < [rs columnCount]; i++) {
            //列名
            NSString *columnName = [rs columnNameForIndex:i];
            //进行数据库列名到model之间的映射转换，拿到属性名
            NSString *propertyName;
            
            if(mapping) {
                propertyName = mapping[columnName];
                if (propertyName == nil) {
                    propertyName = columnName;
                }
            } else {
                propertyName = columnName;
            }
            
            objc_property_t objProperty = class_getProperty(modelClass, propertyName.UTF8String);
            //如果属性不存在，则不操作
            if (objProperty) {
                if(![rs columnIndexIsNull:i]) {
                    [self setProperty:model value:rs columnName:columnName propertyName:propertyName property:objProperty];
                }
            }
            
            NSAssert(![propertyName isEqualToString:@"description"], @"description为自带方法，不能对description进行赋值，请使用其他属性名或请ColumnPropertyMappingDelegate进行映射");
        }
        
        //执行自定义操作
        if (block) {
            block(model, rs);
        }
        
        [models addObject:model];
    }
    [rs close];
    
    return models;
}

/**
 *  进行属性赋值
 */
- (void)setProperty:(id)model value:(FMResultSet *)rs columnName:(NSString *)columnName propertyName:(NSString *)propertyName property:(objc_property_t)property
{
    //    @"f":@"float",
    //    @"i":@"int",
    //    @"d":@"double",
    //    @"l":@"long",
    //    @"c":@"BOOL",
    //    @"s":@"short",
    //    @"q":@"long",
    //    @"I":@"NSInteger",
    //    @"Q":@"NSUInteger",
    //    @"B":@"BOOL",
    
    NSString *firstType = [[[[NSString stringWithUTF8String:property_getAttributes(property)] componentsSeparatedByString:@","] firstObject] substringFromIndex:1];
    
    
    if ([firstType isEqualToString:@"f"]) {
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.floatValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"i"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.intValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"d"]){
        [model setValue:[rs objectForColumnName:columnName] forKey:propertyName];
        
    } else if([firstType isEqualToString:@"l"] || [firstType isEqualToString:@"q"]){
        [model setValue:[rs objectForColumnName:columnName] forKey:propertyName];
        
    } else if([firstType isEqualToString:@"c"] || [firstType isEqualToString:@"B"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.boolValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"s"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.shortValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"I"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.integerValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"Q"]){
        NSNumber *number = [rs objectForColumnName:columnName];
        [model setValue:@(number.unsignedIntegerValue) forKey:propertyName];
        
    } else if([firstType isEqualToString:@"@\"NSData\""]){
        NSData *value = [rs dataForColumn:columnName];
        [model setValue:value forKey:propertyName];
        
    } else if([firstType isEqualToString:@"@\"NSDate\""]){
        NSDate *value = [rs dateForColumn:columnName];
        [model setValue:value forKey:propertyName];
        
    } else if([firstType isEqualToString:@"@\"NSString\""]){
        NSString *value = [rs stringForColumn:columnName];
        [model setValue:value forKey:propertyName];
        
    } else {
        [model setValue:[rs objectForColumnName:columnName] forKey:propertyName];
    }
}

@end
