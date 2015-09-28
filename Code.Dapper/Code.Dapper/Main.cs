using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Dapper;

namespace Code.DapWrapper
{
    public class Main
    {
        /// <summary>
        /// 取数据，执行存储过程，带参数
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc"></param>
        /// <param name="procParams"></param>
        /// <returns></returns>
        public static List<T> InnerQuery<T>(String connString, String proc, DynamicParameters procParams)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.Query<T>(proc, procParams, commandType: CommandType.StoredProcedure).ToList<T>();
            }

        }

        /// <summary>
        /// 取数据，执行存储过程，无参数
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc"></param>
        /// <returns></returns>
        public static List<T> InnerQuery<T>(String connString, String proc)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.Query<T>(proc, commandType: CommandType.StoredProcedure).ToList<T>();
            }
        }

        /// <summary>
        /// 取数据，返回多个结果集的读取方式
        /// </summary>
        /// <typeparam name="T">返回类型</typeparam>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc">存储过程名</param>
        /// <param name="procParams">参数</param>
        /// <param name="readResult">对结果集的处理函数</param>
        /// <returns></returns>
        public static T InnerQueryMultiple<T>(String connString, String proc, DynamicParameters procParams, Func<Dapper.SqlMapper.GridReader, T> readResult)
        {
            IDbConnection conn = null;
            Dapper.SqlMapper.GridReader reader = null;

            try
            {
                conn = new SqlConnection(connString);

                reader = conn.QueryMultiple(proc, procParams, commandType: CommandType.StoredProcedure);

                return readResult(reader);

            }
            finally
            {
                if (reader != null)
                    reader.Dispose();
                if (conn != null)
                    conn.Dispose();
            }


        }

        /// <summary>
        /// 查询操作，无参数，返回第一行第一列结果
        /// </summary>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc">读取的存储过程</param>
        /// <returns></returns>
        public static T InnerQueryScalar<T>(String connString, String proc)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.ExecuteScalar<T>(proc, commandType: CommandType.StoredProcedure);
            }
        }

        /// <summary>
        /// 查询操作，需参数，返回第一行第一列结果
        /// </summary>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc">读取的存储过程</param>
        /// <param name="procParams">参数</param>
        /// <returns></returns>
        public static T InnerQueryScalar<T>(String connString, String proc, DynamicParameters procParams)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.ExecuteScalar<T>(proc, procParams, commandType: CommandType.StoredProcedure);
            }
        }

        /// <summary>
        /// 执行更新数据库的操作，返回操作结果
        /// </summary>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc">更新数据的存储过程</param>
        /// <returns>操作结果：1成功0失败</returns>
        public static Int32 InnerExecuteScalar(String connString, String proc)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.ExecuteScalar<Int32>(proc, commandType: CommandType.StoredProcedure);
            }
        }

        /// <summary>
        /// 执行PROC，返回影响行数
        /// </summary>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc"></param>
        /// <returns></returns>
        public static Int32 InnerExecute(String connString, String proc)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.Execute(proc, commandType: CommandType.StoredProcedure);
            }
        }

        /// <summary>
        /// 执行SQL，返回影响行数
        /// </summary>
        /// <param name="connString">链接字符串</param>
        /// <param name="sql">sql语句</param>
        /// <param name="sqlParams">参数</param>
        /// <returns></returns>
        public static Int32 InnerExecuteSql(String connString, String sql, DynamicParameters sqlParams)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.Execute(sql, sqlParams, commandType: CommandType.Text);
            }
        }


        /// <summary>
        /// 执行PROC，返回影响行数
        /// </summary>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc"></param>
        /// <param name="procParams">参数</param>
        /// <returns></returns>
        public static Int32 InnerExecute(String connString, String proc, DynamicParameters procParams)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.Execute(proc, procParams, commandType: CommandType.StoredProcedure);
            }
        }
        /// <summary>
        /// 执行SQL，返回影响行数
        /// </summary>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc"></param>
        /// <param name="procParams">参数</param>
        /// <returns></returns>
        public static Int32 InnerExecuteText(String connString, String sql)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.Execute(sql, commandType: CommandType.Text);
            }
        }
        /// <summary>
        /// 执行存储过程，无参数,长时间 
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="connString">链接字符串</param>
        /// <param name="proc"></param>
        /// <returns></returns>
        public static List<T> InnerQueryLongTime<T>(String connString, String proc)
        {
            using (IDbConnection conn = new SqlConnection(connString))
            {
                return conn.Query<T>(proc, commandType: CommandType.StoredProcedure, commandTimeout: 600).ToList<T>();
            }
        }
    }
}
