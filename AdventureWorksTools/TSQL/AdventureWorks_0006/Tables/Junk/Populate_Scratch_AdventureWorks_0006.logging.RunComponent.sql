




    INSERT
      logging.RunComponent
        (
            RunComponentName
          , RunComponentDesc
          , SequentialPosition
          , ParentRunComponentID
        )
      VALUES
        (
            'Test Component Base'    -- RunComponentName
          , NULL  -- RunComponentDesc
          , NULL  -- SequentialPosition
          , NULL  -- ParentRunComponentID
        )


    SELECT CreatedRunComponentID = SCOPE_IDENTITY()



    INSERT
      logging.RunComponent
        (
            RunComponentName
          , RunComponentDesc
          , SequentialPosition
          , ParentRunComponentID
        )
      VALUES
        (
            'Test Component Base'    -- RunComponentName
          , NULL  -- RunComponentDesc
          , NULL  -- SequentialPosition
          , 2  -- ParentRunComponentID
        )



