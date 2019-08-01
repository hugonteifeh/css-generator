{-# LANGUAGE DeriveGeneric,  OverloadedStrings #-}

module Utility where

import Numeric (showFFloat)
import qualified Data.Text as T
import Data.Aeson.Types

decInd = "  " :: T.Text

showFullPrecision :: Float -> String
showFullPrecision x = showFFloat Nothing x ""

varName :: T.Text -> T.Text
varName x = "var(--" <> x <> ")"

unwrap :: Value -> T.Text
unwrap (String val) = val