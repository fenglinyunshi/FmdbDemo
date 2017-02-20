//
//  ViewController.m
//  FmdbDemo
//
//  Created by ZhengXiankai on 15/7/21.
//  Copyright (c) 2015年 ZhengXiankai. All rights reserved.
//

#import "ViewController.h"
#import "DbService.h"
#import "PersonModel.h"
#import "FMDatabaseQueue.h"
#import "FMEncryptDatabase.h"
#import "FMEncryptHelper.h"

@interface ViewController ()
{
    NSString *dbPath1;
    NSString *dbPath2;
    
    NSString *originKey;
    NSString *newKey;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    dbPath1 = [directory stringByAppendingPathComponent:@"db1.db"];
    dbPath2 = [directory stringByAppendingPathComponent:@"db2.db"];

    originKey = @"aaa";
    newKey = @"bbb";
    
    [FMEncryptDatabase setEncryptKey:originKey];
}

- (IBAction)createUnencryptDb1:(id)sender
{
    DbService *dbService = [[DbService alloc] initWithPath:dbPath1 encrypt:NO];
    [self createTable:dbService];
    [self insertPeople:dbService];
    [[[UIAlertView alloc] initWithTitle:nil message:@"创建成功" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];
}

- (IBAction)createEncryptDb2:(id)sender
{
    [FMEncryptDatabase setEncryptKey:originKey];
    DbService *dbService = [[DbService alloc] initWithPath:dbPath2 encrypt:YES];
    [self createTable:dbService];
    [self insertPeople:dbService];
    [[[UIAlertView alloc] initWithTitle:nil message:@"创建成功" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];

}


- (IBAction)readUnencryptDb1:(id)sender
{
    DbService *dbService = [[DbService alloc] initWithPath:dbPath1 encrypt:NO];
    NSInteger count = [dbService rowCount:@"People"];
    [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"读取出%ld个人", count] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];
}

- (IBAction)readEncryptDb2:(id)sender
{
    [FMEncryptDatabase setEncryptKey:originKey];
    DbService *dbService = [[DbService alloc] initWithPath:dbPath2 encrypt:YES];
    NSInteger count = [dbService rowCount:@"People"];
    [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"读取出%ld个人", count] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];
}

- (IBAction)encryptDb1:(id)sender
{
    [FMEncryptHelper encryptDatabase:dbPath1];
    [[[UIAlertView alloc] initWithTitle:nil message:@"加密成功" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];
}


- (IBAction)unencryptDb2:(id)sender
{
    [FMEncryptHelper unEncryptDatabase:dbPath2];
    [[[UIAlertView alloc] initWithTitle:nil message:@"解密成功" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];
}


- (IBAction)readEncryptDb1:(id)sender
{
    [FMEncryptDatabase setEncryptKey:originKey];
    DbService *dbService = [[DbService alloc] initWithPath:dbPath1 encrypt:YES];
    NSInteger count = [dbService rowCount:@"People"];
    [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"读取出%ld个人", count] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];

}

- (IBAction)readUnencryptDb2:(id)sender
{
    DbService *dbService = [[DbService alloc] initWithPath:dbPath2 encrypt:NO];
    NSInteger count = [dbService rowCount:@"People"];
    [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"读取出%ld个人", count] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];
}


- (IBAction)changeDb1EncryptKey:(id)sender
{
    [FMEncryptHelper changeKey:dbPath1 originKey:originKey newKey:newKey];
    [[[UIAlertView alloc] initWithTitle:nil message:@"改密成功" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];
}

- (IBAction)readEncryptDb1WithNewKey:(id)sender
{
    [FMEncryptDatabase setEncryptKey:newKey];
    DbService *dbService = [[DbService alloc] initWithPath:dbPath1 encrypt:YES];
    NSInteger count = [dbService rowCount:@"People"];
    [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"读取出%ld个人", count] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];
}

- (IBAction)deleteDb:(id)sender
{
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:dbPath1 error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:dbPath2 error:&error];
    
    if (error) {
        [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"删除失败：%@", error] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];

    } else {
        [[[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"删除成功"] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"好的", nil] show];

    }
}


#pragma mark - Private Method
- (BOOL)createTable:(DbService *)service
{
    NSString *sql = @"CREATE TABLE People (                     \
                        id INTEGER PRIMARY KEY AUTOINCREMENT,   \
                        str1 TEXT,                              \
                        str2 TEXT,                              \
                        float1 REAL,                            \
                        double1 INTEGER,                        \
                        short1 REAL,                            \
                        long1 REAL,                             \
                        date1 TEXT,                             \
                        bool1 INTEGER,                          \
                        data1 BLOB                              \
    )";
    return [service executeUpdate:sql param:nil];
}

- (void)insertPeople:(DbService *)service
{
    NSString *sql = @"insert into People(str1, str2, float1, double1, short1, long1, date1, bool1, data1) values(?,?,?,?,?,?,?,?,?)";
    
    NSString *text = @"dataValue";
    NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
    
    NSArray *param = @[@"bomo", @"male", @70, @175l, @22, @123, [NSDate date], @NO, data];
    
    
    for (int i = 0; i < 100; i++) {
        [service executeUpdate:sql param:param];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
