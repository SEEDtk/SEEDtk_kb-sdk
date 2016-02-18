/*
A KBase module: SEEDtk
This module contains various methods for accessing SEEDtk.
*/

module SEEDtk {
    /*
        A string representing a ContigSet id.
    */
    typedef string contigset_id;

    typedef string genome_id;
    typedef string genome_name;

    /*
        A string representing a workspace name.
    */
    typedef string workspace_name;

    /*
        A string representing a output object name.
    */
    typedef string outputObject;


    /* description of a role missing in the contigs */

    typedef structure {
        string reaction_id;
        string reaction_name;
    } ReactionItem;

    typedef structure {
        string role_id;
        string role_description;
        int genome_hits;
        float blast_score;
        float perc_identity;
        string hit_location;
        string protein_sequence;
        list<ReactionItem> reactions;
    } MissingRoleItem;

    /* description of a role found in the contigs */
    typedef structure {
        string role_id;
        string role_description;
    } FoundRoleItem;

    /* description of a close genome */
    typedef structure {
        genome_id id;
        int hit_count;
        genome_name name;
    } CloseGenomeItem;

    typedef structure {
        contigset_id contigset_id;
        list<MissingRoleItem> missing_roles;
        list<CloseGenomeItem> close_genomes;
        list<FoundRoleItem> found_roles;
    } MissingRoleData;


    /*
        find missing roles in a set of contigs
    */
    funcdef missing_roles(workspace_name, genome_id, outputObject) returns (MissingRoleData) authentication required;
};
