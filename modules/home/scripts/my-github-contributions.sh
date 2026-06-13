USER="sonicpanther101"
gh api graphql -f query="
{
  user(login: \"$USER\") {
    contributionsCollection {
      contributionCalendar {
        weeks {
          contributionDays {
            contributionCount
          }
        }
      }
    }
  }
}" | jq -r '
  .data.user.contributionsCollection.contributionCalendar.weeks as $weeks
  | "GITHUB (last ~3 months)",
    "",
    (["Sun","Mon","Tue","Wed","Thu","Fri","Sat"] as $days
      | range(0;7) as $d
      | $days[$d] + " " +
        ($weeks
          | map(.contributionDays[$d].contributionCount)
          | map(
              if . == 0 then "·"
              elif . < 4 then "░"
              elif . < 7 then "▒"
              elif . < 10 then "▓"
              else "█" end
            )
          | join("")
        )
    )
'