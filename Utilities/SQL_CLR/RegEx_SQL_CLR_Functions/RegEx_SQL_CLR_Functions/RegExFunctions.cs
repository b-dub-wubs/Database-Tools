using System;
using System.IO;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;

public partial class UDF
{
  /*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
    │ RegEx Utility Functions                                                                     │
  \*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Options Enumeration Combiner                                       │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlInt32 RegExOptionEnumeration (
                                                      SqlBoolean IgnoreCase
                                                    , SqlBoolean SingleLine
                                                    , SqlBoolean MultiLine
                                                    , SqlBoolean IgnorePatternWhitespace
                                                    , SqlBoolean ExplicitCapture
                                                    , SqlBoolean RightToLeft
                                                    , SqlBoolean ECMAScript
                                                    , SqlBoolean CultureInvariant
                                                  )
  {
    if (IgnoreCase.IsNull)
    { IgnoreCase = SqlBoolean.False; }

    if (SingleLine.IsNull)
    { SingleLine = SqlBoolean.False; }

    if (MultiLine.IsNull)
    { MultiLine = SqlBoolean.False; }

    if (IgnorePatternWhitespace.IsNull)
    { IgnorePatternWhitespace = SqlBoolean.False; }

    if (ExplicitCapture.IsNull)
    { ExplicitCapture = SqlBoolean.False; }

    if (RightToLeft.IsNull)
    { RightToLeft = SqlBoolean.False; }

    if (ECMAScript.IsNull)
    { ECMAScript = SqlBoolean.False; }

    if (CultureInvariant.IsNull)
    { CultureInvariant = SqlBoolean.False; }

    RegexOptions regex_ops = RegexOptions.None;

    if (IgnoreCase.IsTrue)
    {
      regex_ops = regex_ops | RegexOptions.IgnoreCase;
    }

    if (SingleLine.IsTrue)
    {
      regex_ops = regex_ops | RegexOptions.Singleline;
    }

    if (MultiLine.IsTrue)
    {
      regex_ops = regex_ops | RegexOptions.Multiline;
    }

    if (IgnorePatternWhitespace.IsTrue)
    {
      regex_ops = regex_ops | RegexOptions.IgnoreCase;
    }

    if (ExplicitCapture.IsTrue)
    {
      regex_ops = regex_ops | RegexOptions.IgnoreCase;
    }

    if (RightToLeft.IsTrue)
    {
      regex_ops = regex_ops | RegexOptions.IgnoreCase;
    }

    if (ECMAScript.IsTrue)
    {
      regex_ops = regex_ops | RegexOptions.IgnoreCase;
    }

    if (CultureInvariant.IsTrue)
    {
      regex_ops = regex_ops | RegexOptions.IgnoreCase;
    }

    return Convert.ToInt32(regex_ops);
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx Excape                                           │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlString RegExEscape(SqlString input)
  {
    if (String.IsNullOrEmpty(input.ToString()))
    {
      return SqlString.Null;
    }
    else
    {
      return new SqlString(Regex.Escape(input.ToString()));
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx Unexcape                                         │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlString RegExUnescape(SqlString input)
  {
    if (String.IsNullOrEmpty(input.ToString()))
    {
      return SqlString.Null;
    }
    else
    {
      return new SqlString(Regex.Unescape(input.ToString()));
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Get the index of a RegEx match                                     │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlInt16 RegExIndex(SqlString input, SqlString pattern, SqlInt32 options/*, SqlInt16 timeout*/)
  {
    if (String.IsNullOrEmpty(pattern.ToString()) || String.IsNullOrEmpty(input.ToString()) /*|| (Int16)timeout < 0*/)
    {
      return SqlInt16.Null;
    }
    else
    {
      RegexOptions regex_ops = RegexOptions.None;

      if (!options.IsNull)
        regex_ops = (RegexOptions)(Int32)(options);

      return Convert.ToInt16(Regex.Match(input.ToString(), pattern.ToString(), regex_ops).Index);
    }
  }
  
  /*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
    │ Interpreted RegEx wrapper functions for SQL CLR                                             │
  \*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx IsMatch                                          │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic =true, IsPrecise = true)]
    public static SqlBoolean IsMatch(SqlString input, SqlString pattern, SqlInt32  options/*, SqlInt16 timeout*/)
    {
      if (String.IsNullOrEmpty(pattern.ToString()) || String.IsNullOrEmpty(input.ToString()) /*|| (Int16)timeout < 0*/)
      {
        return SqlBoolean.Null;
      }
      else
      {
        RegexOptions regex_ops = RegexOptions.None;

        if (!options.IsNull)
          regex_ops = (RegexOptions)(Int32)(options);

        //if((Int16)timeout == 0)
        //  return Regex.IsMatch(input.ToString(), pattern.ToString(), regex_ops); 
        //else
        //  return Regex.IsMatch(input.ToString(), pattern.ToString(), regex_ops/*, TimeSpan.FromSeconds((double)timeout)*/);
        return Regex.IsMatch(input.ToString(), pattern.ToString(), regex_ops);
      }
    }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx Match                                            │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlString Match(SqlString input, SqlString pattern, SqlInt32 options/*, SqlInt16 timeout*/)
  {
    if (String.IsNullOrEmpty(input.ToString()) || String.IsNullOrEmpty(pattern.ToString()))
    {
      return new SqlString(null);
    }
    else
    {
      RegexOptions regex_ops = RegexOptions.None;

      if (!options.IsNull)
        regex_ops = (RegexOptions)(Int32)(options);

      //if ((Int16)timeout == 0)
      //{
      //  Match m = Regex.Match(input.ToString(), pattern.ToString(), regex_ops);
      //  return new SqlString(m.Success ? m.Value : null);
      //}
      //else
      //{
      //  Match m = Regex.Match(input.ToString(), pattern.ToString(), regex_ops/*, TimeSpan.FromSeconds((double)timeout)*/);
      //  return new SqlString(m.Success ? m.Value : null);
      //}
      Match m = Regex.Match(input.ToString(), pattern.ToString(), regex_ops);
      return new SqlString(m.Success ? m.Value : null);
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx GroupMatch                                       │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlString GroupMatch(SqlString input, SqlString pattern, SqlString group, SqlInt32 options/*, SqlInt16 timeout*/)
  {
    if (String.IsNullOrEmpty(input.ToString()) || String.IsNullOrEmpty(pattern.ToString()) || String.IsNullOrEmpty(group.ToString()) /*|| (Int16)timeout < 0*/)
    {
      return new SqlString(null);
    }
    else
    {
      RegexOptions regex_ops = RegexOptions.None;

      if (!options.IsNull)
        regex_ops = (RegexOptions)(Int32)(options);

      //if ((Int16)timeout == 0)
      //{
      //  Group g = Regex.Match(input.ToString(), pattern.ToString(), regex_ops).Groups[group.ToString()];
      //  return new SqlString(g.Success ? g.Value : null);
      //}
      //else
      //{
      //  Group g = Regex.Match(input.ToString(), pattern.ToString(), regex_ops/* , TimeSpan.FromSeconds((double)timeout)*/).Groups[group.ToString()];
      //  return new SqlString(g.Success ? g.Value : null);
      //}

      Group g = Regex.Match(input.ToString(), pattern.ToString(), regex_ops).Groups[group.ToString()];
      return new SqlString(g.Success ? g.Value : null);
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    ? Wrapper for RegEx Replace                                          ?
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlString Replace(SqlString input, SqlString pattern, SqlString replacement, SqlInt32 options/*, SqlInt16 timeout*/)
  {
    // the replacement string is not checked for an empty string because that is a valid replacement pattern
    if (String.IsNullOrEmpty(input.ToString()) || String.IsNullOrEmpty(pattern.ToString()) || replacement == null /*|| (Int16)timeout < 0*/)
    {
      return new SqlString(null);
    }
    else
    {
      RegexOptions regex_ops = RegexOptions.None;

      if (!options.IsNull)
        regex_ops = (RegexOptions)(Int32)(options);

      //if ((Int16)timeout == 0)
      //  return new SqlString(Regex.Replace(input.ToString(), pattern.ToString(), replacement.ToString(), regex_ops));
      //else
      //  return new SqlString(Regex.Replace(input.ToString(), pattern.ToString(), replacement.ToString(), regex_ops/* , TimeSpan.FromSeconds((double)timeout)*/));
      return new SqlString(Regex.Replace(input.ToString(), pattern.ToString(), replacement.ToString(), regex_ops));
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx Matches                                          │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [SqlFunction(   DataAccess = DataAccessKind.None
                , FillRowMethodName = "FillMatches"
                , TableDefinition = "Position int, MatchText nvarchar(max)"
                , IsPrecise = true
                , IsDeterministic = true  )]
  public static IEnumerable Matches(SqlString input, SqlString pattern, SqlInt32 options/*, SqlInt16 timeout*/)
  {
    List<RegexMatch> MatchCollection = new List<RegexMatch>();
    if (!String.IsNullOrEmpty(input.ToString()) && !String.IsNullOrEmpty(pattern.ToString()) /*&& (Int16)timeout >= 0*/)
    {
      RegexOptions regex_ops = RegexOptions.None;

      if (!options.IsNull)
        regex_ops = (RegexOptions)(Int32)(options);

      //if ((Int16)timeout == 0)
      //{
      //  //only run through the matches if the inputs have non-empty, non-null strings
      //  foreach (Match m in Regex.Matches(input.ToString(), pattern.ToString(), regex_ops))
      //  {
      //    MatchCollection.Add(new RegexMatch(m.Index, m.Value));
      //  }
      //}
      //else
      //{
      //  //only run through the matches if the inputs have non-empty, non-null strings
      //  foreach (Match m in Regex.Matches(input.ToString(), pattern.ToString(), regex_ops/* , TimeSpan.FromSeconds((double)timeout)*/))
      //  {
      //    MatchCollection.Add(new RegexMatch(m.Index, m.Value));
      //  }
      //}

      //only run through the matches if the inputs have non-empty, non-null strings
      foreach (Match m in Regex.Matches(input.ToString(), pattern.ToString(), regex_ops))
      {
        MatchCollection.Add(new RegexMatch(m.Index, m.Value));
      }
    }
    return MatchCollection;
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx Split                                            │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [SqlFunction(   DataAccess = DataAccessKind.None
                , FillRowMethodName = "FillMatches"
                , TableDefinition = "Position int, MatchText nvarchar(max)"
                , IsPrecise = true, IsDeterministic = true  )]
  public static IEnumerable Split(SqlString input, SqlString pattern, SqlInt32 options/*, SqlInt16 timeout*/)
  {
    List<RegexMatch> MatchCollection = new List<RegexMatch>();
    if (!String.IsNullOrEmpty(input.ToString()) && !String.IsNullOrEmpty(pattern.ToString()) /*&& (Int16)timeout >= 0*/)
    {
      RegexOptions regex_ops = RegexOptions.None;

      if (!options.IsNull)
        regex_ops = (RegexOptions)(Int32)(options);

      //only run through the splits if the inputs have non-empty, non-null strings
      String[] splits = Regex.Split(input.ToString(), pattern.ToString(), regex_ops);
      for (int i = 0; i < splits.Length; i++)
      {
        MatchCollection.Add(new RegexMatch(i, splits[i]));
      }
    }
    return MatchCollection;
  }

  /*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
    │ Compiled RegEx wrapper functions for SQL CLR                                                │
    ├─────────────────────────────────────────────────────────────────────────────────────────────┤
        The idea here is to store compiled regular expressions, serialized into a byte array and
        converted to a SqlBytes type to be stored as a column value in a database table 
        (or variable) of type VARBINARY, then pass this value to to the following set of CLR
        wrapper functions, which will deserialized the compiled RegEx and use the compiled 
        verison in the wrapped regex operation
  \*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Compiles a RegEx to be stored for later use in the database        │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [return: SqlFacet(MaxSize = -1)]
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlBytes CompileRegEx(SqlString pattern, SqlInt32 options/*, SqlInt16 timeout*/)
  {
    if (String.IsNullOrEmpty(pattern.ToString()) /*|| (Int16)timeout < 0*/)
    {
      return SqlBytes.Null;
    }
    else
    {
      RegexOptions regex_ops = RegexOptions.None;

      if (!options.IsNull)
        regex_ops = (RegexOptions)(Int32)(options);

      regex_ops = regex_ops | RegexOptions.Compiled;

      //if ((Int16)timeout == 0)
      //  return SerializeCompiledRegEx(new Regex(pattern.ToString(), regex_ops));
      //else
      //  return SerializeCompiledRegEx(new Regex(pattern.ToString(), regex_ops/* , TimeSpan.FromSeconds((double)timeout)*/));
      return SerializeCompiledRegEx(new Regex(pattern.ToString(), regex_ops));
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx IsMatch - Compiled                               │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlBoolean IsMatchC(SqlString input, SqlBytes compiled_regex)
  {
    if (compiled_regex.IsNull || String.IsNullOrEmpty(input.ToString()))
    {
      return SqlBoolean.Null;
    }
    else
    {
      Regex thisRegex = DeserializeCompiledRegex(compiled_regex);
      return thisRegex.IsMatch(input.ToString());
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx Match - Compiled                                 │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlString MatchC(SqlString input, SqlBytes compiled_regex)
  {
    if (String.IsNullOrEmpty(input.ToString()))
    {
      return new SqlString(null);
    }
    else
    {
      Regex thisRegex = DeserializeCompiledRegex(compiled_regex);
      Match m = thisRegex.Match(input.ToString());
      return new SqlString(m.Success ? m.Value : null);
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx GroupMatch - Compiled                            │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlString GroupMatchC(SqlString input, SqlBytes compiled_regex, SqlString group)
  {
    if (String.IsNullOrEmpty(input.ToString()) || String.IsNullOrEmpty(group.ToString()))
    {
      return new SqlString(null);
    }
    else
    {
      Regex thisRegex = DeserializeCompiledRegex(compiled_regex);
      Group g = thisRegex.Match(input.ToString()).Groups[group.ToString()];
      return new SqlString(g.Success ? g.Value : null);
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx Replace - Compiled                               │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlString ReplaceC(SqlString input, SqlBytes compiled_regex, SqlString replacement)
  {
    // the replacement string is not checked for an empty string because that is a valid replacement pattern
    if (String.IsNullOrEmpty(input.ToString()) || replacement == null)
    {
      return new SqlString(null);
    }
    else
    {
      Regex thisRegex = DeserializeCompiledRegex(compiled_regex);
      return new SqlString(thisRegex.Replace(input.ToString(), replacement.ToString()));
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx Matches  - Compiled                              │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [SqlFunction(   DataAccess = DataAccessKind.None
                , FillRowMethodName = "FillMatches"
                , TableDefinition = "Position int, MatchText nvarchar(max)"
                , IsPrecise = true
                , IsDeterministic = true  )]
  public static IEnumerable MatchesC(SqlString input, SqlBytes compiled_regex)
  {
    List<RegexMatch> MatchCollection = new List<RegexMatch>();
    if (!String.IsNullOrEmpty(input.ToString()))
    {
      Regex thisRegex = DeserializeCompiledRegex(compiled_regex);
      //only run through the matches if the inputs have non-empty, non-null strings
      foreach (Match m in thisRegex.Matches(input.ToString()))
      {
        MatchCollection.Add(new RegexMatch(m.Index, m.Value));
      }
    }
    return MatchCollection;
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Wrapper for RegEx Split  - Compiled                                │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [SqlFunction(   DataAccess = DataAccessKind.None
                , FillRowMethodName = "FillMatches"
                , TableDefinition = "Position int, MatchText nvarchar(max)"
                , IsPrecise = true
                , IsDeterministic = true  )]
  public static IEnumerable SplitC(SqlString input, SqlBytes compiled_regex)
  {
    List<RegexMatch> MatchCollection = new List<RegexMatch>();
    if (!String.IsNullOrEmpty(input.ToString()))
    {
      Regex thisRegex = DeserializeCompiledRegex(compiled_regex);
      //only run through the splits if the inputs have non-empty, non-null strings
      String[] splits = thisRegex.Split(input.ToString());
      for (int i = 0; i < splits.Length; i++)
      {
        MatchCollection.Add(new RegexMatch(i, splits[i]));
      }
    }
    return MatchCollection;
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Get the index of a RegEx match - Compiled                          │
  \*└────────────────────────────────────────────────────────────────────┘*/
  [Microsoft.SqlServer.Server.SqlFunction(IsDeterministic = true, IsPrecise = true)]
  public static SqlInt16 RegExIndexC(SqlString input, SqlBytes compiled_regex)
  {
    if (String.IsNullOrEmpty(input.ToString()))
    {
      return SqlInt16.Null;
    }
    else
    {
      Regex thisRegex = DeserializeCompiledRegex(compiled_regex);
      return Convert.ToInt16(thisRegex.Match(input.ToString()).Index);
    }
  }

  /*┌─────────────────────────────────────────────────────────────────────────────────────────────┐*\
    │ Helper Functions & Private Classes                                                          │
  \*└─────────────────────────────────────────────────────────────────────────────────────────────┘*/

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Represents RegEx Match item                                        │
  \*└────────────────────────────────────────────────────────────────────┘*/
  private class RegexMatch
  {
    public SqlInt32 Position { get; set; }
    public SqlString MatchText { get; set; }

    public RegexMatch(SqlInt32 position, SqlString match)
    {
      this.Position = position;
      this.MatchText = match;
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Helper for Split and Matches Wrappers                              │
  \*└────────────────────────────────────────────────────────────────────┘*/
  public static void FillMatches(object match, out SqlInt32 Position, out SqlString MatchText)
  {
    RegexMatch rm = (RegexMatch)match;
    Position = rm.Position;
    MatchText = rm.MatchText;
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Serializes a complied RegEx into a SqlBytes object                 │
  \*└────────────────────────────────────────────────────────────────────┘*/
  private static SqlBytes SerializeCompiledRegEx(Regex this_regex)
  {
    if (this_regex == null)
      return SqlBytes.Null;
    BinaryFormatter bf = new BinaryFormatter();
    using (MemoryStream ms = new MemoryStream())
    {
      bf.Serialize(ms, this_regex);
      return new SqlBytes(ms.ToArray());
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Serializes a complied RegEx into a SqlBytes object                 │
  \*└────────────────────────────────────────────────────────────────────┘*/
  public static SqlDouble JarrowWinklerProximity(SqlString str1, SqlString str2)
  {
    if (String.IsNullOrEmpty(str1.ToString()) || String.IsNullOrEmpty(str2.ToString()))
    {
      return SqlSingle.Null;
    }
    else
    {  
      return (double)JaroWinklerDistance.proximity(str1.ToString(),str2.ToString());
    }
  }

  /*┌────────────────────────────────────────────────────────────────────┐*\
    │ Deserializes a SqlBytes object into a compiled RegEx               │
  \*└────────────────────────────────────────────────────────────────────┘*/
  private static Regex DeserializeCompiledRegex(SqlBytes compiled_regex)
  {
    BinaryFormatter bf = new BinaryFormatter();
    using (MemoryStream ms = new MemoryStream(compiled_regex.Buffer))
    {
      //object obj = bf.Deserialize(ms);
      return (Regex)bf.Deserialize(ms);
    }
  }

  public static class JaroWinklerDistance
  {
    /* The Winkler modification will not be applied unless the 
     * percent match was at or above the mWeightThreshold percent 
     * without the modification. 
     * Winkler's paper used a default value of 0.7
     */
    private static readonly double mWeightThreshold = 0.7;

    /* Size of the prefix to be concidered by the Winkler modification. 
     * Winkler's paper used a default value of 4
     */
    private static readonly int mNumChars = 4;

    /// <summary>
    /// Returns the Jaro-Winkler distance between the specified  
    /// strings. The distance is symmetric and will fall in the 
    /// range 0 (perfect match) to 1 (no match). 
    /// </summary>
    /// <param name="aString1">First String</param>
    /// <param name="aString2">Second String</param>
    /// <returns></returns>
    public static double distance(string aString1, string aString2)
    {
      return 1.0 - proximity(aString1, aString2);
    }

    /// <summary>
    /// Returns the Jaro-Winkler distance between the specified  
    /// strings. The distance is symmetric and will fall in the 
    /// range 0 (no match) to 1 (perfect match). 
    /// </summary>
    /// <param name="aString1">First String</param>
    /// <param name="aString2">Second String</param>
    /// <returns></returns>
    public static double proximity(string aString1, string aString2)
    {
      int lLen1 = aString1.Length;
      int lLen2 = aString2.Length;
      if (lLen1 == 0)
        return lLen2 == 0 ? 1.0 : 0.0;

      int lSearchRange = Math.Max(0, Math.Max(lLen1, lLen2) / 2 - 1);

      // default initialized to false
      bool[] lMatched1 = new bool[lLen1];
      bool[] lMatched2 = new bool[lLen2];

      int lNumCommon = 0;
      for (int i = 0; i < lLen1; ++i)
      {
        int lStart = Math.Max(0, i - lSearchRange);
        int lEnd = Math.Min(i + lSearchRange + 1, lLen2);
        for (int j = lStart; j < lEnd; ++j)
        {
          if (lMatched2[j]) continue;
          if (aString1[i] != aString2[j])
            continue;
          lMatched1[i] = true;
          lMatched2[j] = true;
          ++lNumCommon;
          break;
        }
      }
      if (lNumCommon == 0) return 0.0;

      int lNumHalfTransposed = 0;
      int k = 0;
      for (int i = 0; i < lLen1; ++i)
      {
        if (!lMatched1[i]) continue;
        while (!lMatched2[k]) ++k;
        if (aString1[i] != aString2[k])
          ++lNumHalfTransposed;
        ++k;
      }
      // System.Diagnostics.Debug.WriteLine("numHalfTransposed=" + numHalfTransposed);
      int lNumTransposed = lNumHalfTransposed / 2;

      // System.Diagnostics.Debug.WriteLine("numCommon=" + numCommon + " numTransposed=" + numTransposed);
      double lNumCommonD = lNumCommon;
      double lWeight = 
                        (
                            lNumCommonD / lLen1
                          + lNumCommonD / lLen2
                          + (lNumCommon - lNumTransposed) / lNumCommonD
                        ) 
                        / 3.0;

      if (lWeight <= mWeightThreshold) return lWeight;
      int lMax = Math.Min(mNumChars, Math.Min(aString1.Length, aString2.Length));
      int lPos = 0;
      while (lPos < lMax && aString1[lPos] == aString2[lPos])
        ++lPos;
      if (lPos == 0) return lWeight;
      return lWeight + 0.1 * lPos * (1.0 - lWeight);
    }
  }
}