//
//  DbService.h
//  FmdbDemo
//
//  Created by ZhengXiankai on 15/7/21.
//  Copyright (c) 2015年 ZhengXiankai. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FMResultSet;
@class FMDatabaseQueue;

@interface DbService : NSObject


@property (nonatomic, strong) FMDatabaseQueue *queue;

- (instancetype)initWithPath:(NSString *)path encrypt:(BOOL)isEncrypted;


/**
 *  查询第一行第一列的数据
 */
- (id)executeScalar:(NSString *)sql param:(NSArray *)param;

/**
 *  查询行数
 */
- (NSInteger)rowCount:(NSString *)tableName;

/**
 *  更新数据
 */
- (BOOL)executeUpdate:(NSString *)sql param:(NSArray *)param;



#pragma mark - 查询操作自动构建Model

/**
 *  执行查询操作，自定构造models集合
 *
 *  @param sql        sql语句
 *  @param args       sql参数
 *  @param modelClass 结果集model类型
 *
 *  @return 查询结果集
 */
- (NSArray *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)args modelClass:(Class)modelClass;

/**
 *  执行查询操作，自定构造models集合
 *
 *  @param sql        sql语句
 *  @param args       sql参数
 *  @param modelClass 结果集model类型
 *  @param block      对model执行自定义操作
 *
 *  @return 查询结果集
 */

- (NSArray *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)args modelClass:(Class)modelClass performBlock:(void (^)(id model, FMResultSet *rs))block;

/**
 *  查询结果集取得model集合
 *
 *  @param rs         数据库查询结果集
 *  @param modelClass 结果集model类型
 *
 *  @return 查询结果集
 */
- (NSArray *)resultForModels:(FMResultSet *)rs modelClass:(Class)modelClass;

/**
 *  查询结果集取得model集合
 *
 *  @param rs         数据库查询结果集
 *  @param modelClass 结果集model类型
 *  @param block      对model执行自定义操作
 *
 *  @return 查询结果集
 */
- (NSArray *)resultForModels:(FMResultSet *)rs modelClass:(Class)modelClass performBlock:(void (^)(id model, FMResultSet *rs))block;


@end
